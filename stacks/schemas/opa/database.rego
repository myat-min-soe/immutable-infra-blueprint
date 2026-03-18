package atmos.validation

# By default, the configuration is valid
default valid = false

# The schema is valid if there are no errors
valid {
    count(errors) == 0
}

# Enforce that Production databases must be highly available (Multi-AZ)
errors[msg] {
    input.vars.environment == "production"
    input.vars.multi_az != true
    msg := "Validation Failed: Production database must have multi_az set to true for High Availability."
}

# Require max_allocated_storage to be at least 100GB in production
errors[msg] {
    input.vars.environment == "production"
    input.vars.max_allocated_storage < 100
    msg := "Validation Failed: Production database must have max_allocated_storage >= 100 GB."
}
