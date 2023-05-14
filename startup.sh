sudo apt install vim-gtk3 ripgrep fzf bat vlc -y

# apache
sudo apt install apache2 -y
mkdir -p $HOME/www
sudo chgrp -R www-data $HOME/www
chmod -R 750 $HOME/www
sudo sed -i "s|/var/www/html|$HOME/www|g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s|/var/www/html|$HOME/www|g" /etc/apache2/sites-available/default-ssl.conf

sudo cat << EOF >> /etc/apache2/apache2.conf
<Directory /home/eladzlot/www>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
EOF

systemctl start apache2
systemctl enable apache2

# chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

install_chrome_extension () {
  preferences_dir_path="/opt/google/chrome/extensions"
  pref_file_path="$preferences_dir_path/$1.json"
  upd_url="https://clients2.google.com/service/update2/crx"
  mkdir -p "$preferences_dir_path"
  echo "{" > "$pref_file_path"
  echo "  \"external_update_url\": \"$upd_url\"" >> "$pref_file_path"
  echo "}" >> "$pref_file_path"
  echo Added \""$pref_file_path"\" ["$2"]
}

install_chrome_extension "cfhdojbkjhnklbpkdaibdccddilifddb" "adblock plus"
install_chrome_extension "hdokiejnpimakedhajhdlcegeplioahd" "Lastpass"
install_chrome_extension "ldipcbpaocekfooobnbcddclnhejkcpn" "Google scholar button"
install_chrome_extension "ekhagklcjbdpajgpjgmbionohlpdbjgc" "Zotero connector"

# zoom
wget https://zoom.us/client/latest/zoom_amd64.deb
sudo apt install ./zoom_amd64.deb -y

# zettlr
wget -O zettlr.deb https://github.com/Zettlr/Zettlr/releases/download/v1.8.2/Zettlr-1.8.2-amd64.deb
sudo dpkg -i zettlr.deb

# Zotero
wget -qO- https://github.com/retorquere/zotero-deb/releases/download/apt-get/install.sh | sudo bash
sudo apt install zotero --fix-missing # seems there is a problem here?
# Need to install manually:  https://github.com/retorquere/zotero-better-bibtex

# exporting
sudo apt install texlive-latex-extra biber -y
wget -O pandoc.deb https://github.com/jgm/pandoc/releases/download/2.11.3.1/pandoc-2.11.3.1-1-amd64.deb
sudo dpkg -i pandoc.deb

# setup R
sudo apt install r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev -y

R --vanilla << EOF
    install.packages(c("tidyverse"), repos='http://cran.us.r-project.org')
    install.packages(c("coda","mvtnorm","devtools","loo","dagitty","DiagrammeR))
    devtools::install_github("rmcelreath/rethinking")

    Sys.setenv(DOWNLOAD_STATIC_LIBV8 = 1) # only necessary for Linux without the nodejs library / headers
    install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE)
    q()
EOF

#rstudio
wget -O rstudio.deb https://download1.rstudio.org/desktop/jammy/amd64/rstudio-2022.02.3-492-amd64.deb
#https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2022.02.2-485-amd64.deb
sudo dpkg -i rstudio.deb
sudo apt -f install -y
