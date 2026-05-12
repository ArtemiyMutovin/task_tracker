class ServiceResult
  attr_reader :object, :errors

  def initialize(success:, object: nil, errors: [])
    @success = success
    @object = object
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
