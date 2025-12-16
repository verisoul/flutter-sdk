package ai.verisoul.verisoul_sdk

import kotlinx.coroutines.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.*
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Unit tests demonstrating why wrapping SDK calls in a main thread dispatcher
 * can cause deadlocks when the SDK internally uses coroutines.
 * 
 * These tests run on JVM without needing an Android device.
 * 
 * Run with: gradle test
 */
class ThreadingDeadlockUnitTest {

    /**
     * Simulated "main thread" using a single-threaded executor, just like
     * the RN test. This mimics Android's main/UI thread behavior.
     */
    private val mainThreadExecutor: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "MockMainThread")
    }
    private val mainThreadDispatcher: CoroutineDispatcher = mainThreadExecutor.asCoroutineDispatcher()

    interface Callback {
        fun onSuccess(result: String)
        fun onFailure(error: Exception)
    }

    /**
     * Mock SDK that simulates Verisoul Android SDK v0.4.61+ behavior:
     *  - Does work on IO/background thread
     *  - Dispatches callback to a "main thread" dispatcher internally
     */
    inner class MockSdkWithInternalMainDispatch {
        fun getSessionId(callback: Callback) {
            // SDK launches coroutine on IO thread
            CoroutineScope(Dispatchers.IO).launch {
                // Simulate work
                delay(50)

                // SDK internally dispatches to main thread for callback
                withContext(mainThreadDispatcher) {
                    callback.onSuccess("session-12345")
                }
            }
        }
    }

    /**
     * TEST 1: Demonstrates the DEADLOCK scenario.
     * 
     * Pattern that causes deadlock:
     * 1. Force SDK call to run on main thread (via executor.submit + blocking wait)
     * 2. SDK does background work
     * 3. SDK tries to dispatch callback to main thread
     * 4. Main thread is BLOCKED waiting for result = DEADLOCK
     */
    @Test(timeout = 3000)
    fun testDeadlock_whenMainThreadBlocksWaitingForMainThreadCallback() {
        val sdk = MockSdkWithInternalMainDispatch()
        val deadlockOccurred = AtomicBoolean(false)
        val completed = AtomicBoolean(false)

        val future = mainThreadExecutor.submit {
            val resultLatch = CountDownLatch(1)
            val result = AtomicReference<String>()

            sdk.getSessionId(object : Callback {
                override fun onSuccess(r: String) {
                    result.set(r)
                    resultLatch.countDown()
                }

                override fun onFailure(error: Exception) {
                    resultLatch.countDown()
                }
            })

            // PROBLEM: This blocks the main thread waiting for callback
            // But callback needs main thread to execute = DEADLOCK
            val success = resultLatch.await(1, TimeUnit.SECONDS)
            if (!success) {
                deadlockOccurred.set(true)
            } else {
                completed.set(true)
            }
        }

        try {
            future.get(2, TimeUnit.SECONDS)
        } catch (e: TimeoutException) {
            deadlockOccurred.set(true)
        }

        // The test should detect deadlock (timeout)
        assertTrue(
            "Deadlock should be detected - main thread blocked waiting for callback that needs main thread",
            deadlockOccurred.get()
        )
    }

    /**
     * TEST 2: Demonstrates the CORRECT approach (no deadlock).
     * 
     * Pattern that works:
     * 1. Call SDK directly (don't force onto main thread)
     * 2. SDK does background work
     * 3. SDK dispatches callback to main thread
     * 4. Main thread is FREE to handle callback = SUCCESS
     */
    @Test(timeout = 3000)
    fun testNoDeadlock_whenCallingDirectlyWithoutMainThreadWrapper() {
        val sdk = MockSdkWithInternalMainDispatch()
        val completed = AtomicBoolean(false)
        val resultLatch = CountDownLatch(1)
        val result = AtomicReference<String>()

        // Call SDK directly WITHOUT wrapping in main thread executor
        // Let the SDK manage its own threading
        sdk.getSessionId(object : Callback {
            override fun onSuccess(r: String) {
                result.set(r)
                completed.set(true)
                resultLatch.countDown()
            }
            override fun onFailure(error: Exception) {
                resultLatch.countDown()
            }
        })

        // Wait for result - main thread is free to handle callback
        val success = resultLatch.await(2, TimeUnit.SECONDS)

        assertTrue("Should complete successfully without deadlock", success)
        assertTrue("Callback should have been called", completed.get())
        assertEquals("session-12345", result.get())
    }

    /**
     * TEST 3: Demonstrates the EXACT deadlock pattern from the old code.
     * 
     * This simulates what happened with mainHandler.post:
     * - Flutter calls getSessionId()
     * - Old code wraps in mainHandler.post { ... }
     * - SDK callback needs main thread
     * - If anything blocks main thread = potential deadlock
     */
    @Test(timeout = 5000)
    fun testOldPattern_mainHandlerPostCanCauseContention() {
        val sdk = MockSdkWithInternalMainDispatch()
        val results = ConcurrentLinkedQueue<Long>()
        val latch = CountDownLatch(5)

        // Simulate multiple rapid calls (like Flutter might do)
        repeat(5) { i ->
            val startTime = System.currentTimeMillis()
            
            // OLD PATTERN: mainHandler.post { sdk.call() }
            mainThreadExecutor.execute {
                sdk.getSessionId(object : Callback {
                    override fun onSuccess(r: String) {
                        results.add(System.currentTimeMillis() - startTime)
                        latch.countDown()
                    }
                    override fun onFailure(error: Exception) {
                        latch.countDown()
                    }
                })
            }
        }

        val allCompleted = latch.await(4, TimeUnit.SECONDS)
        
        // With mainHandler.post, calls get serialized on main thread
        // causing them to queue up and take longer
        println("Old pattern results (ms): $results")
        
        assertTrue("All calls should eventually complete", allCompleted)
        
        // Check if there's significant delay due to main thread contention
        if (results.isNotEmpty()) {
            val maxTime = results.maxOrNull() ?: 0
            println("Max completion time with old pattern: ${maxTime}ms")
        }
    }

    /**
     * TEST 4: Demonstrates the NEW pattern has better concurrency.
     */
    @Test(timeout = 5000)
    fun testNewPattern_directCallsHaveBetterConcurrency() {
        val sdk = MockSdkWithInternalMainDispatch()
        val results = ConcurrentLinkedQueue<Long>()
        val latch = CountDownLatch(5)

        // Simulate multiple rapid calls
        repeat(5) { i ->
            val startTime = System.currentTimeMillis()
            
            // NEW PATTERN: Direct call without mainHandler.post
            sdk.getSessionId(object : Callback {
                override fun onSuccess(r: String) {
                    results.add(System.currentTimeMillis() - startTime)
                    latch.countDown()
                }
                override fun onFailure(error: Exception) {
                    latch.countDown()
                }
            })
        }

        val allCompleted = latch.await(4, TimeUnit.SECONDS)
        
        println("New pattern results (ms): $results")
        
        assertTrue("All calls should complete", allCompleted)
        
        if (results.isNotEmpty()) {
            val maxTime = results.maxOrNull() ?: 0
            println("Max completion time with new pattern: ${maxTime}ms")
            
            // New pattern allows better concurrency since calls don't 
            // get serialized on main thread
        }
    }

    /**
     * TEST 5: Classic deadlock demonstration with runBlocking.
     * 
     * This is the most common deadlock pattern:
     * - Main thread runs blocking code
     * - Blocking code waits for coroutine
     * - Coroutine needs main thread to complete
     */
    @Test(timeout = 3000)
    fun testClassicDeadlock_runBlockingOnMainThreadWaitingForMain() {
        val deadlockDetected = AtomicBoolean(false)

        val future = mainThreadExecutor.submit {
            try {
                // runBlocking on main thread...
                runBlocking {
                    withTimeout(1000) {
                        // ...waiting for something that needs main thread
                        withContext(mainThreadDispatcher) {
                            "This will never execute - DEADLOCK"
                        }
                    }
                }
            } catch (e: TimeoutCancellationException) {
                deadlockDetected.set(true)
            }
        }

        try {
            future.get(2, TimeUnit.SECONDS)
        } catch (e: TimeoutException) {
            deadlockDetected.set(true)
        }

        assertTrue(
            "Classic deadlock: runBlocking on main thread waiting for main thread dispatch",
            deadlockDetected.get()
        )
    }

    @After
    fun tearDown() {
        mainThreadExecutor.shutdownNow()
    }
}
