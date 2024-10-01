import os
from flask import Flask, request, jsonify, send_from_directory
import bibtexparser
import smtplib
from email.mime.text import MIMEText

app = Flask(__name__)

def parse_bibtex():
    with open('publications.bib', 'r') as bibtex_file:
        bibtex_str = bibtex_file.read()
    bib_database = bibtexparser.loads(bibtex_str)
    publications = []
    for entry in bib_database.entries:
        authors = entry.get('author', 'No authors').replace(' and ', ', ')
        journal_or_booktitle = entry.get('journal', entry.get('booktitle', 'Unknown Journal or Conference'))
        publication = {
            'title': entry.get('title', 'No title'),
            'authors': authors,
            'journal': journal_or_booktitle,
            'volume': entry.get('volume', ''),
            'issue': entry.get('number', ''),
            'pages': entry.get('pages', ''),
            'year': entry.get('year', ''),
            'doi': entry.get('doi', ''),
            'url': entry.get('url', '')
        }
        publications.append(publication)
    return publications

@app.route('/publications.json')
def get_publications():
    publications = parse_bibtex()
    return jsonify(publications)

@app.route('/')
def serve_index():
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def serve_file(path):
    return send_from_directory('.', path)

@app.route('/send_message', methods=['POST'])
def send_message():
    data = request.json
    name = data.get('name')
    email = data.get('email')
    message = data.get('message')

    # Send email
    try:
        send_email(name, email, message)
        return jsonify({'success': True})
    except Exception as e:
        print(f"Error sending email: {e}")
        return jsonify({'success': False})

def send_email(name, email, message):
    sender_email = os.getenv('USER_EMAIL')
    sender_password = os.getenv('USER_PASS')
    recipient_email = "skajale@mit.edu"

    msg = MIMEText(f"Name: {name}\nEmail: {email}\nMessage: {message}")
    msg['Subject'] = 'New Contact Form Submission'
    msg['From'] = sender_email
    msg['To'] = recipient_email

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, recipient_email, msg.as_string())

if __name__ == '__main__':
    app.run(debug=True)  # Change the port here
