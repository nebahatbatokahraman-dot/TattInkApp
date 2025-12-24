const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Email transporter configuration
// Note: You need to configure your email service (Gmail, SendGrid, etc.)
const transporter = nodemailer.createTransport({
  service: 'gmail', // Change to your email service
  auth: {
    user: functions.config().email.user, // Set via: firebase functions:config:set email.user="your-email@gmail.com"
    pass: functions.config().email.password, // Set via: firebase functions:config:set email.password="your-app-password"
  },
});

// Send email verification
exports.sendEmailVerification = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  if (!email) return null;

  const actionCodeSettings = {
    url: 'https://yourapp.com/verify-email', // Change to your app URL
    handleCodeInApp: true,
  };

  try {
    const link = await admin.auth().generateEmailVerificationLink(email, actionCodeSettings);
    
    const mailOptions = {
      from: functions.config().email.user,
      to: email,
      subject: 'TattInk - Email Doğrulama',
      html: `
        <h2>Email Adresinizi Doğrulayın</h2>
        <p>TattInk hesabınızı aktifleştirmek için aşağıdaki linke tıklayın:</p>
        <a href="${link}">Email Adresimi Doğrula</a>
        <p>Bu link 24 saat geçerlidir.</p>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log('Email verification sent to:', email);
  } catch (error) {
    console.error('Error sending email verification:', error);
  }
});

// Send artist approval email
exports.sendArtistApprovalEmail = functions.firestore
  .document('artist_approvals/{approvalId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send email if status changed to approved
    if (before.status !== 'approved' && after.status === 'approved') {
      const email = after.email;
      const artistName = `${after.firstName} ${after.lastName}`;

      try {
        const mailOptions = {
          from: functions.config().email.user,
          to: email,
          subject: 'TattInk - Artist Hesabınız Onaylandı',
          html: `
            <h2>Hesabınız Onaylandı!</h2>
            <p>Merhaba ${artistName},</p>
            <p>TattInk artist hesabınız başarıyla onaylandı. Artık paylaşım yapabilir, mesaj atabilir ve fotoğraf beğenebilirsiniz.</p>
            <p>Uygulamaya giriş yaparak başlayabilirsiniz.</p>
            <p>İyi çalışmalar!</p>
          `,
        };

        await transporter.sendMail(mailOptions);
        console.log('Approval email sent to:', email);
      } catch (error) {
        console.error('Error sending approval email:', error);
      }
    }

    // Send rejection email if status changed to rejected
    if (before.status !== 'rejected' && after.status === 'rejected') {
      const email = after.email;
      const artistName = `${after.firstName} ${after.lastName}`;
      const rejectionReason = after.rejectionReason || 'Belirtilmemiş';

      try {
        const mailOptions = {
          from: functions.config().email.user,
          to: email,
          subject: 'TattInk - Artist Başvurunuz Hakkında',
          html: `
            <h2>Başvurunuz Hakkında</h2>
            <p>Merhaba ${artistName},</p>
            <p>Maalesef artist başvurunuz onaylanamadı.</p>
            <p><strong>Red Sebebi:</strong> ${rejectionReason}</p>
            <p>Yeni bir başvuru oluşturabilir veya eksik bilgileri tamamlayarak tekrar başvurabilirsiniz.</p>
            <p>Sorularınız için bizimle iletişime geçebilirsiniz.</p>
          `,
        };

        await transporter.sendMail(mailOptions);
        console.log('Rejection email sent to:', email);
      } catch (error) {
        console.error('Error sending rejection email:', error);
      }
    }

    return null;
  });

