

I am building a Flutter app using Clean Architecture + Dio + Riverpod. I need rules to generate a Dio Interceptor for handling token authentication, automatic token refresh, and single-flight lock mechanism for concurrent requests.

Requirements & Constraints for AI:

Token Storage Abstraction (Domain/Data Layer):

Interact ONLY through an abstract TokenRepository interface defined in domain/repositories/ (methods: getAccessToken(), getRefreshToken(), saveTokens(), clearTokens()).

Implementation uses flutter_secure_storage inside data/repositories/. Never use SharedPreferences.

Dio AuthInterceptor Rules (Data/Core Network Layer):

onRequest: Inject Authorization: Bearer <accessToken> into every protected request.

onError (401 Handling): Intercept 401 Unauthorized responses (ignore endpoints like /auth/refresh or /auth/login).

Single-Flight Refresh Mechanism:

Maintain a boolean _isRefreshing flag and a Completer<String?>? _refreshCompleter.

If multiple protected requests fail with 401 concurrently, ONLY the first request must trigger the POST /auth/refresh API call.

Subsequent 401 requests MUST wait for _refreshCompleter.future to complete without making duplicate refresh API calls.

Once refreshed, save new tokens and transparently retry all queued original requests using handler.resolve(await dio.fetch(options)).

Refresh Token Failure:

If /auth/refresh fails or throws an error, call tokenRepository.clearTokens(), reject the interceptor handler, and notify the app/UI state to navigate to the login screen.

Isolated Dio Instance: Use a clean, isolated Dio instance inside _handleTokenRefresh() (without the AuthInterceptor) to avoid infinite loops.

Testing Requirements:

Provide unit tests using http_mock_adapter or mocktail.

Test must simulate 3 concurrent 401 requests and assert that /auth/refresh is called EXACTLY 1 TIME before all 3 requests complete successfully.