# Find the Dockerfile for mcr.microsoft.com/azure-functions/powershell:3.0-powershell${VARIANT}-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/dev/host/3.0/buster/amd64/powershell

# Update the VARIANT arg in devcontainer.json to pick a supported PowerShell version: 7, 6
ARG VARIANT=7
FROM mcr.microsoft.com/azure-functions/powershell:3.0-powershell${VARIANT}-core-tools

# Add PowerShell package registry
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb && \
  dpkg -i packages-microsoft-prod.deb

RUN apt-get update

# Install Pwsh
RUN apt-get install -y powershell

# Git stuff REALLY REALLY slows down the shell when using linux containers on Windows, so turn it off
RUN git config --global oh-my-zsh.hide-info 1
