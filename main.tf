
resource "null_resource" "build" {
  triggers = {
    sha1 = sha1(join("", [for f in fileset("${var.root_path}/${var.name}/${var.src_path}", "**") : filesha1("${var.root_path}/${var.name}/${var.src_path}/${f}")]))
  }

  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "${var.root_path}/${var.name}"
  }

  provisioner "local-exec" {
    command     = "aws s3 sync ${var.root_path}/${var.name}/${var.dist_directory} s3://${var.bucket_name}/${var.name}"
    working_dir = path.module
  }

}