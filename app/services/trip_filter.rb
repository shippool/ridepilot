class TripFilter 

  attr_reader :trips, :filters

  def initialize(trips, filters = {})
    @trips = trips
    @filters = filters
  end

  def filter!
    filter_by_pickup_time!
    filter_by_days_of_week!
    filter_by_vehicle!
    filter_by_driver!
    filter_by_status!

    @filters.each do |k, v|
      next if [:start, :end, :days_of_week, :vehicle_id, :driver_id, :status_id].index(k) # has been processed above

      @trips = @trips.where("#{k}": v) if !v.blank?
    end

    @trips
  end

  private 

  def parse_datetime(time_param)
    return if !time_param.present? 

    # this is to parse calendar params
    # will be deprecated after new calendar gets in
    if time_param.to_i.to_s == time_param.to_s
      time = Time.at(time_param.to_i)
    else
      time = Date.strptime(time_param, '%d-%b-%Y %a') rescue nil
    end

    time.to_date.in_time_zone if time
  end

  def filter_by_pickup_time!
    t_start = parse_datetime(@filters[:start]) 
    t_end = parse_datetime(@filters[:end]) 

    if !t_start && !t_end
      time    = Time.now
      t_start = time.beginning_of_week.to_date.in_time_zone
      t_end   = t_start + 6.days
    elsif !t_end
      t_end   = t_start + 6.days
    elsif !t_start
      t_start   = t_end - 6.days
    end

    @trips = @trips.
      where("pickup_time >= '#{t_start.beginning_of_day.strftime "%Y-%m-%d %H:%M:%S"}'").
      where("pickup_time <= '#{t_end.end_of_day.strftime "%Y-%m-%d %H:%M:%S"}'").order(:pickup_time)
    
    @filters[:start] = t_start.to_i
    @filters[:end] = t_end.to_i
  end

  def filter_by_days_of_week!
    days_of_week = @filters[:days_of_week].blank? ? "0,1,2,3,4,5,6" : @filters[:days_of_week]
    @trips = @trips.where('extract(dow from pickup_time) in (?)', days_of_week.split(','))
    @filters[:days_of_week] = days_of_week
  end

  def filter_by_vehicle!
    if @filters[:vehicle_id].present?  
      if @filters[:vehicle_id].to_i == -1
        @trips = @trips.where(cab: true)
      else
        @trips = @trips.includes(run: :vehicle).references(run: :vehicle).where("runs.vehicle_id": @filters[:vehicle_id]) 
      end
    end
  end

  def filter_by_driver!
    if @filters[:driver_id].present?  
      @trips = @trips.includes(run: :driver).references(run: :driver).where("runs.driver_id": @filters[:driver_id]) 
    end
  end

  def filter_by_status!
    if @filters[:status_id].present?  
      if @filters[:status_id].to_i == 1
        @trips = @trips.where("run_id is NOT NULL or cab = true")
      else
        @trips = @trips.where("run_id is NULL and cab = false")
      end
    end
  end

end