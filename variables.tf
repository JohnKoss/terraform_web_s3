variable "name" {
  type        = string
  description = "Used to create full paths locally and in S3."
}

variable "root_path" {
  type        = string
  description = "Full path to the root of the project (path to package json)."
}

variable "build_cmd" {
  type        = string
  description = "Name of the package.json build script (e.g. build_dev or build_prod)."
}

variable "src_path" {
  type        = string
  description = "Relative path (to the root_path) of the source files."
}

variable "dist_directory" {
  type        = string
  description = "Relative path (to the root_path) of the compiled files."
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket. Will be used in the S3 path."
}
