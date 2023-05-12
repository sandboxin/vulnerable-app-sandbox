# Define the provider
provider "google" {
  credentials = file("credentials.json")
  project     = "playground-s-11-830254cf"
  region      = "us-central1"
}

# Create a VM instance
resource "google_compute_instance" "vm_instance" {
  name         = "test-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata = {
    ssh-keys = "adminuser:${file("./id_rsa.pub")}"
  }

  connection {
    type        = "ssh"
    user        = "adminuser"
    private_key = file("./id_rsa")
    host        = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash adminuser",
      "echo 'newuser:Password@123' | sudo chpasswd",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y docker-compose",
      "wget https://raw.githubusercontent.com/vulhub/vulhub/master/jenkins/CVE-2018-1000861/docker-compose.yml",
      "sudo docker-compose up -d"
    ]
  }

  network_interface {
    network = "default"
    access_config {
      // Make Static external IP
      nat_ip = google_compute_address.vm_address.address
    }
  }
}

# Create a static external IP address
resource "google_compute_address" "vm_address" {
  name = "test-vm-address"
}

# Create a firewall rule that opens port 8080
resource "google_compute_firewall" "vm_firewall" {
  name    = "test-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}
