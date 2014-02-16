<h1>TripParser: <font size="-1">DHPD EMAIL Pages Report Generator.</font></h1>
<blockquote>
<h2><a href="trip-parser/" target="_blank">Open TripParser...</a></h2>
<h2><a href="http://popmedic.com/trips/trip-parser/report.example.html">Example HTML report</a></h2>
</blockquote>

<H2>Usage:</H2>
<blockquote>
<h3>Email</h3>
	<blockquote>
    Put the email address of where your CAD pages go.  You can use a "/" and 
	Folder/Label name.  For example I have a Label in my gmail account for "Trip" 
    filtering the INBOX for any message with the text "TRIP:" in the body.  To only 
    parse the "Trip" label, use the email "you@gmail.com/Trip"  My email is 
    kscardina.dhpd333@gmail.com so to use the Label Trip I would use the email 
    address "kscardina.dhpd333@gmail.com/Trip" (without the quotes of course).
    </blockquote>
<h3>Password</h3>
	<blockquote>
    This is where you put the password to the email account.  This will 
	be encode with a 128 cypher encoding that would be pretty hard to figure out.
    TripParser needs this password because it will be downloading messages from 
    this email account and parsing them for pages so we can build the report.
    </blockquote>
<h3>Create Reports</h3>
	<blockquote>
	Click on the Create Reports button to start creating your reports. Once the 
	reports are generated from parsing your emails, the buttons on the bottom will be
    enabled.  Clicking on the button will open that format of report.
    </blockquote>
	<blockquote style="background-color:#F00;">
    YOU WILL GET A AUTHERIZATION ERROR THE FIRST TIME YOU USE THIS.  Your gmail 
	account has a security feature to keep other clients out. You will get an email from google seconds after 
    you run this tool the first time.  In the email there is a link to allow this client to access your emails. 
    follow the link and allow access.
    </blockquote>
</blockquote>
<hr />
<h2>Objective:</h2>
<blockquote>
To build a tool for parsing pages sent by email to gmail and creating a report from
this data
</blockquote>
<h2>Background:</h2>
<blockquote>
This project was constructed to parse pages sent to my gmail account for the calls
I run at DHPD so that I could collect data on scene times, response times, overall 
trip times, and crew utilization hours.<br />
<br />
DHPD used to use pagers for verifying trips for the crews.  These pages where sent 
at the beginning of the call to your pager telling your "Times" (Dispatched time, 
On scene time, Departed scene time, Hospital time)  I always want to collect those 
times and see what my average times where.  Recently we switched to "emailing" these 
pages, and I can now save the pages and create reports on my "times" and average times
like I always wanted.
</blockquote>
<h2>Technologies:</h2>
<blockquote>
This tool uses IMAP to access a gmail account though a ruby script.  JQuery and Javascript
are used for the web front end that uses a php layer to talk to the ruby server script.  The
stdout of the ruby script is piped into a status file so that the front end can see the progress.
<br />
<br />
The code for the told project can be seen at my github project repositories.
</blockquote>
<h2>Security:</h2>
<blockquote>
Yes, you will be sending my server a gmail password.  This could be dangerous, but I do salt the password.
I use a cypher-key encoding on the password before sending it, and I do not store this password at all. <br />
 
My "pager email" is an account on gmail that I receive nothing but CAD emails at, what do I care about the 
privacy.  That is why I am comfortable doing this.<br />
<br />
I removed the addresses from the reports to avoid any type of HIPA anything!
</blockquote>
