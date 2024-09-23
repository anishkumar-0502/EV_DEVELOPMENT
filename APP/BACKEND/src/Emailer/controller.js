const nodemailer = require('nodemailer');

// Create a transporter object
let transporter = nodemailer.createTransport({
  host: 'smtppro.zoho.in', // replace with your SMTP server
  port: 465, // 465 for SSL or 587 for TLS
  secure: true, // true for SSL, false for TLS
  auth: {
    user: 'vivek@outdidtech.com', // your email
    pass: 'vivek30091998.', // your email password
  },
});

// Function to send email
async function sendEmail(to, subject, text) {
  try {
    // Define email options
    let info = await transporter.sendMail({
      from: '"EV POWER" <vivek@outdidtech.com>', // sender address
      to: to, // list of receivers
      subject: subject, // Subject line
      text: text, // plain text body
      html: `<p>${text}</p>`, // HTML body
    });

    console.log('Message sent: %s', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
}

async function EmailConfig(email,otp){
    try{
        let sendTo = email;
        let mail_subject = 'EV POWER - FORGET PASSWORD OTP';
        let mail_body = `Hello ${email},

                        We received a request to reset your password. Please use the following One-Time Password (OTP) to proceed with the password reset process:

                        Your OTP is: ${otp}

                        Thank you,
                        EV POWER`;

        const result = await sendEmail(sendTo, mail_subject, mail_body);
        return result;

    }catch(error){
        console.error('Error sending email:', error);
        return false;
    }
}

module.exports = {EmailConfig}