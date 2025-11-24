sealed class Result<out T> {
  const factory Result.success(T data) = Success;
  const factory Result.failure(String message) = Failure;
}

class Success<T> implements Result<T> {
  final T data;
  const Success(this.data);
}

class Failure implements Result<Never> {
  final String message;
  const Failure(this.message);
}
