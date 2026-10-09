    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        _error = e.response!.data['message'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _error = 'اتصال به سرور برقرار نشد. آدرس سایت را بررسی کنید.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'عدم دسترسی به اینترنت یا آدرس سایت اشتباه است.';
      } else {
        _error = 'خطا در اتصال به سرور.';
      }
