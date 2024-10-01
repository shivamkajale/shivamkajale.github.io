document.addEventListener("DOMContentLoaded", function() {
    const publicationsList = document.getElementById("publications-list");
    const contactForm = document.getElementById("contact-form");
    const carouselSlide = document.querySelector(".carousel-slide");
    const carouselItems = document.querySelectorAll(".carousel-item");
    const pauseSign = document.getElementById("pause-sign");

    let currentIndex = 0;
    let isPaused = false;

    function showImage(index) {
        carouselSlide.style.transform = `translateX(-${index * 100}%)`;
    }

    function startCarousel() {
        setInterval(() => {
            if (!isPaused) {
                currentIndex = (currentIndex + 1) % carouselItems.length;
                showImage(currentIndex);
            }
        }, 4000);
    }

    function togglePause() {
        isPaused = !isPaused;
        pauseSign.style.display = isPaused ? 'block' : 'none';
    }

    carouselItems.forEach((item, index) => {
        item.addEventListener("click", togglePause);
    });

    showImage(currentIndex);
    startCarousel();

    // Fetch publications from the JSON file
    fetch('publications.json')
        .then(response => response.json())
        .then(data => {
            publicationsList.innerHTML = '';
            data.forEach(pub => {
                const listItem = document.createElement("li");
                const doiLink = pub.doi ? `<a href="${pub.url}" target="_blank">doi:${pub.doi}</a>` : '';
                listItem.innerHTML = `
                    <div style="margin-left: 20px;">
                        <strong>${pub.title}</strong><br>
                        ${pub.authors}<br>
                        ${pub.journal ? `${pub.journal}` : ''}${pub.volume ? ', vol. ' + pub.volume : ''}${pub.issue ? ', no. ' + pub.issue : ''}${pub.pages ? ', pp. ' + pub.pages : ''}${doiLink ? ', ' + doiLink : ''} (${pub.year})
                    </div>
                `;
                publicationsList.appendChild(listItem);
            });
        })
        .catch(error => console.error("Error fetching publications:", error));

    // Handle contact form submission
    contactForm.addEventListener("submit", function(event) {
        event.preventDefault();

        const formData = new FormData(contactForm);
        const name = formData.get("name");
        const email = formData.get("email");
        const message = formData.get("message");

        fetch("/send_message", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ name, email, message })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert("Message sent successfully!");
                contactForm.reset();
            } else {
                alert("Failed to send message. Please try again later.");
            }
        })
        .catch(error => console.error("Error sending message:", error));
    });
});
