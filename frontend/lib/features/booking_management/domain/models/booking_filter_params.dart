class BookingFilterParams {
  final String? status;
  final String? city;
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int skip;
  final int limit;

  const BookingFilterParams({
    this.status,
    this.city,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.skip = 0,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      if (status != null && status!.isNotEmpty && status != 'all') 'status': status,
      if (city != null && city!.isNotEmpty && city != 'all') 'city': city,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (dateFrom != null) 'date_from': dateFrom!.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo!.toIso8601String(),
      'skip': skip,
      'limit': limit,
    };
  }

  BookingFilterParams copyWith({
    String? status,
    String? city,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? skip,
    int? limit,
  }) {
    return BookingFilterParams(
      status: status ?? this.status,
      city: city ?? this.city,
      search: search ?? this.search,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
    );
  }
}
