sudo apt install vim-gtk3 ripgrep code vlc -y

# chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# zettlr
wget https://github.com/Zettlr/Zettlr/releases/download/v1.8.2/Zettlr-1.8.2-amd64.deb
sudo dpkg -i Zettlr-1.8.2-amd64.deb

# setup R
sudo apt install r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev -y

R --vanilla << EOF
    install.packages(c("tidyverse"), repos='http://cran.us.r-project.org')
    install.packages(c("coda","mvtnorm","devtools","loo","dagitty"))
    devtools::install_github("rmcelreath/rethinking")

    Sys.setenv(DOWNLOAD_STATIC_LIBV8 = 1) # only necessary for Linux without the nodejs library / headers
    install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE)
    q()
EOF

#rstudio
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.3.1093-amd64.deb
sudo dpkg -i rstudio-1.3.1093-amd64.deb
sudo apt -f install -y

# todo:
#apache
#zoom
