#from requests_html import HTMLSession
from bs4 import BeautifulSoup
import requests
import random
from urllib.parse import urlparse, urlunparse
import re
import time
import json

class RequestService:
    def __init__(self):
        #self.session = HTMLSession()

        self.user_agent_list = [
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:77.0) Gecko/20100101 Firefox/77.0',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36',
        ]

    def generate_detail_link(self, search_link):
        index_vjk = search_link.find("vjk=")
        if index_vjk != -1:
            start_index = index_vjk + len("vjk=")
            end_index = search_link.find("&", start_index)
            jk_token = search_link[start_index:end_index] if end_index != -1 else search_link[start_index:]
            new_link = f"https://pl.indeed.com/viewjob?jk={jk_token}"
            final_link = new_link.split("&", 1)[0]
            return final_link          
        else:
            return search_link

    def transform_url(self, url):
        index_praca = url.find("/praca/")
        if index_praca != -1:
            new_link = "https://theprotocol.it/szczegoly/praca/" + url[index_praca + len("/praca/"):]
            parsed_url = urlparse(new_link)
            cleaned_url = urlunparse(parsed_url._replace(query=''))
            return cleaned_url
        else:
            return url     

    def extract_company_name(self, url, job_position):
        job_position = job_position.replace(' ', '-')
        job_position = job_position.lower()

        if job_position in url:
            start_index = url.find(job_position)
            company = url[:start_index].strip()
            company = company.rsplit("/", 1)[-1]
            company = re.sub(r'\W+', ' ', company).title()
            return company
        return None

    def data_from_url(self, url):
        
        company_name = None
        job_position = None

        site, job_position, company_name, offer_url = "", "", "", ""
        max_attempts = 3
        timeout_seconds = 8
        attempts = 0

        headers = {'User-Agent': random.choice(self.user_agent_list)}

        while attempts < max_attempts and (not company_name or not job_position):

            try:
                if "pracuj" in url:

                    site = "pracuj.pl"
                    offer_url = url
                    
                    response = requests.get(url, headers=headers)
                    html_content = response.text
                    soup = BeautifulSoup(html_content, "html.parser")

                    job_position_element = soup.find("h1", {"data-scroll-id": "job-title"})
                    if job_position_element:
                        job_position = job_position_element.text.strip()

                    company_name_element = soup.find("h2", {"data-scroll-id": "employer-name"})
                    if company_name_element:
                        company_name = company_name_element.text.split('O firmie')[0].strip()

                
                elif "indeed" in url:
                    new_link = self.generate_detail_link(url)
                    offer_url = new_link
                    site = "indeed.com"
                    
                    response = requests.get(new_link, headers=headers)
                    html_content = response.text
                    
                    for line in html_content.split("\n"):
                        if '"sourceEmployerName":"' in line and not company_name:
                            company_name = line.strip().split('"sourceEmployerName":"')[1].split('"')[0]
                        elif '"jobTitle":"' in line and not job_position:
                            job_position = line.strip().split('"jobTitle":"')[1].split('"')[0]
                            time.sleep(1)


                elif "theprotocol.it" in url:
                    new_link = self.transform_url(url)
                    #offer_url = new_link
                    site = "theprotocol.it"
                    
                    response = requests.get(new_link, headers=headers)
                    time.sleep(1)
                    html_content = response.text
                    time.sleep(1)
                    soup = BeautifulSoup(html_content, "html.parser")

                    job_position_element = soup.find("h1", {"data-test": "text-offerTitle"})
                    if job_position_element:
                        job_position = job_position_element.text.strip()
                    
                    company_name_element = soup.find("a", attrs={"data-test": "anchor-company-link"})
                    if company_name_element:
                        company_name = company_name_element.text.strip()
                    offer_url = new_link

                elif "nofluffjobs" in url:
                
                    site = "nofluffjobs.com"
                    offer_url = url
                    
                    response = requests.get(url, headers=headers)
                    html_content = response.text
                    soup = BeautifulSoup(html_content, "html.parser")

                    script_tag = soup.find("script", {"type": "application/ld+json"})

                    if script_tag:
                        json_data = script_tag.string.strip()
                        data = json.loads(json_data)

                        for item in data["@graph"]:
                            
                            if "@type" in item and item["@type"] == "JobPosting":
                                
                                job_position = item.get("title")
                                company_name = item.get("hiringOrganization", {}).get("name")

                                job_position = job_position.split('@')[0].strip()

                elif "justjoin.it" in url:
                    
                    site = "justjoin.it"
                    offer_url = url
                    
                    response = requests.get(url, headers=headers)
                    html_content = response.text
                    soup = BeautifulSoup(html_content, "html.parser")
                    for line in html_content.split("\n"):
                        if '"companyName":' in line:
                            company_name = line.strip().split('"companyName":"')[1].split('"')[0]
                            break

                    for line in html_content.split("\n"):
                        if '"offer":{"slug":' in line and '"title":' in line:
                            job_position = line.strip().split('"offer":{"slug":')[1].split('"title":"')[1].split('"')[0]
                            break

                elif "linkedin.com" in url:

                    offer_url = url
                    site = "linkedin.com"
                    
                    response = requests.get(url, headers=headers)
                    html_content = response.text

                    soup = BeautifulSoup(html_content, "html.parser")

                    job_position_element = soup.find("h3", {"class": "sub-nav-cta__header"})
                    if job_position_element:
                        job_position = job_position_element.text.strip()

                    company_name_element = soup.find("a", {"class": "sub-nav-cta__optional-url"})
                    if company_name_element:
                        company_name = company_name_element.text.strip()
                
                elif "bulldogjob" in url:
                    
                    site = "bulldogjob.pl"
                    offer_url = url
                    
                    
                    response = requests.get(url, headers=headers)
                    html_content = response.text

                    soup = BeautifulSoup(html_content, "html.parser")
                    script_tags = soup.find_all("script", {"type": "application/ld+json"})


                    for script_tag in script_tags:
                        
                        json_data = script_tag.string.strip()
                        
                        data = json.loads(json_data)

                        if "@type" in data and data["@type"] == "JobPosting" and "hiringOrganization" in data:
                            company_name = data["hiringOrganization"]["name"]
                        if "title" in data:
                            job_position = data["title"]
                                    

            except requests.Timeout:
                print(f"Request timed out after {timeout_seconds} seconds.")
            except Exception as e:
                print(f"Error: {e}")

            attempts += 1
        
        return site, job_position, company_name, offer_url
    
