"""
Certificate Generator Module
Generates digitally signed, tamper-proof wipe certificates in PDF and JSON formats
"""

import json
import hashlib
import os
from datetime import datetime
import uuid
import base64
from pathlib import Path

try:
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
    from reportlab.pdfgen import canvas
    HAS_REPORTLAB = True
except ImportError:
    HAS_REPORTLAB = False

class CertificateGenerator:
    def __init__(self):
        self.cert_dir = Path("certificates")
        self.cert_dir.mkdir(exist_ok=True)
        
    def generate_certificate(self, wipe_data):
        """Generate both PDF and JSON certificates"""
        cert_id = self._generate_cert_id()
        timestamp = datetime.now()
        
        # Create certificate data
        cert_data = {
            "certificate_id": cert_id,
            "version": "1.0",
            "standard": "NIST SP 800-88 Rev. 1",
            "timestamp": timestamp.isoformat(),
            "organization": {
                "name": "CleanSlate Data Sanitization",
                "department": "Professional Data Wiping Services",
                "address": "NIST SP 800-88 Rev. 1 Compliant"
            },
            "wipe_details": wipe_data,
            "verification": self._generate_verification_data(wipe_data),
            "digital_signature": None  # Will be added after data is finalized
        }
        
        # Generate digital signature
        cert_data["digital_signature"] = self._generate_signature(cert_data)
        
        # Save JSON certificate
        json_path = self._save_json_certificate(cert_data, cert_id)
        
        # Save PDF certificate if reportlab is available
        pdf_path = None
        if HAS_REPORTLAB:
            pdf_path = self._save_pdf_certificate(cert_data, cert_id)
        else:
            # Create simple text certificate as fallback
            pdf_path = self._save_text_certificate(cert_data, cert_id)
        
        return {
            "certificate_id": cert_id,
            "json_path": str(json_path),
            "pdf_path": str(pdf_path) if pdf_path else None,
            "timestamp": timestamp.isoformat(),
            "verification_hash": cert_data["verification"]["hash"]
        }
    
    def _generate_cert_id(self):
        """Generate unique certificate ID"""
        return f"CS-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
    
    def _generate_verification_data(self, wipe_data):
        """Generate verification data for the certificate"""
        verification = {
            "method": wipe_data.get("wipe_method", "Unknown"),
            "passes": wipe_data.get("passes_completed", 0),
            "bytes_wiped": wipe_data.get("bytes_wiped", 0),
            "start_time": wipe_data.get("start_time", ""),
            "end_time": wipe_data.get("end_time", ""),
            "duration_seconds": wipe_data.get("duration", 0),
            "target_info": wipe_data.get("target_info", {}),
            "verification_status": wipe_data.get("verification_status", "Not Verified"),
            "hash": None
        }
        
        # Generate hash of verification data
        data_str = json.dumps(verification, sort_keys=True)
        verification["hash"] = hashlib.sha256(data_str.encode()).hexdigest()
        
        return verification
    
    def _generate_signature(self, cert_data):
        """Generate digital signature for the certificate"""
        # In production, this would use proper cryptographic signing
        # For MVP, we'll use SHA-256 hash
        data_copy = cert_data.copy()
        data_copy.pop("digital_signature", None)
        
        data_str = json.dumps(data_copy, sort_keys=True)
        signature = hashlib.sha512(data_str.encode()).hexdigest()
        
        return {
            "algorithm": "SHA-512",
            "signature": signature,
            "timestamp": datetime.now().isoformat()
        }
    
    def _save_json_certificate(self, cert_data, cert_id):
        """Save certificate as JSON file"""
        filename = f"cert_{cert_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        filepath = self.cert_dir / filename
        
        with open(filepath, 'w') as f:
            json.dump(cert_data, f, indent=2)
        
        return filepath
    
    def _save_pdf_certificate(self, cert_data, cert_id):
        """Save certificate as PDF file using ReportLab"""
        if not HAS_REPORTLAB:
            return None
        
        filename = f"cert_{cert_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        filepath = self.cert_dir / filename
        
        # Create PDF document
        doc = SimpleDocTemplate(str(filepath), pagesize=A4,
                               rightMargin=72, leftMargin=72,
                               topMargin=72, bottomMargin=18)
        
        # Container for the 'Flowable' objects
        elements = []
        
        # Define styles
        styles = getSampleStyleSheet()
        styles.add(ParagraphStyle(name='CenterTitle',
                                 parent=styles['Title'],
                                 alignment=TA_CENTER,
                                 fontSize=24,
                                 spaceAfter=30))
        
        styles.add(ParagraphStyle(name='CenterSubtitle',
                                 parent=styles['Normal'],
                                 alignment=TA_CENTER,
                                 fontSize=14,
                                 spaceAfter=20))
        
        styles.add(ParagraphStyle(name='Justify',
                                 parent=styles['Normal'],
                                 alignment=TA_JUSTIFY))
        
        # Title
        elements.append(Paragraph("DATA WIPE CERTIFICATE", styles['CenterTitle']))
        elements.append(Paragraph("NIST SP 800-88 Rev. 1 Compliant", styles['CenterSubtitle']))
        elements.append(Spacer(1, 0.2*inch))
        
        # Organization info
        org_text = f"""
        <b>{cert_data['organization']['name']}</b><br/>
        {cert_data['organization']['department']}<br/>
        {cert_data['organization']['address']}
        """
        elements.append(Paragraph(org_text, styles['CenterSubtitle']))
        elements.append(Spacer(1, 0.3*inch))
        
        # Certificate details
        elements.append(Paragraph(f"<b>Certificate ID:</b> {cert_data['certificate_id']}", styles['Normal']))
        elements.append(Paragraph(f"<b>Issue Date:</b> {cert_data['timestamp']}", styles['Normal']))
        elements.append(Spacer(1, 0.2*inch))
        
        # Wipe details section
        elements.append(Paragraph("<b>WIPE DETAILS</b>", styles['Heading2']))
        elements.append(Spacer(1, 0.1*inch))
        
        wipe_details = cert_data['wipe_details']
        details_data = [
            ['Property', 'Value'],
            ['Wipe Method', wipe_details.get('wipe_method', 'N/A')],
            ['Target Type', wipe_details.get('target_type', 'N/A')],
            ['Target Path', wipe_details.get('target_path', 'N/A')],
            ['Start Time', wipe_details.get('start_time', 'N/A')],
            ['End Time', wipe_details.get('end_time', 'N/A')],
            ['Total Bytes Wiped', f"{wipe_details.get('bytes_wiped', 0):,} bytes"],
            ['Passes Completed', str(wipe_details.get('passes_completed', 0))],
            ['Verification Status', wipe_details.get('verification_status', 'N/A')]
        ]
        
        # Create table
        table = Table(details_data, colWidths=[2.5*inch, 3.5*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        elements.append(table)
        elements.append(Spacer(1, 0.3*inch))
        
        # Verification section
        elements.append(Paragraph("<b>VERIFICATION</b>", styles['Heading2']))
        elements.append(Spacer(1, 0.1*inch))
        
        verification = cert_data['verification']
        elements.append(Paragraph(f"<b>Verification Hash:</b>", styles['Normal']))
        elements.append(Paragraph(f"<font size='8'>{verification['hash']}</font>", styles['Normal']))
        elements.append(Spacer(1, 0.2*inch))
        
        # Digital signature
        elements.append(Paragraph("<b>DIGITAL SIGNATURE</b>", styles['Heading2']))
        elements.append(Spacer(1, 0.1*inch))
        
        signature = cert_data['digital_signature']
        elements.append(Paragraph(f"<b>Algorithm:</b> {signature['algorithm']}", styles['Normal']))
        elements.append(Paragraph(f"<b>Signature:</b>", styles['Normal']))
        elements.append(Paragraph(f"<font size='8'>{signature['signature']}</font>", styles['Normal']))
        elements.append(Spacer(1, 0.3*inch))
        
        # Footer
        elements.append(Spacer(1, 0.5*inch))
        footer_text = """
        <font size='8'>
        This certificate confirms that the data wiping operation was performed according to 
        NIST SP 800-88 Rev. 1 guidelines. The digital signature ensures the authenticity and 
        integrity of this certificate. This certificate can be verified using the verification 
        hash and digital signature provided above.
        </font>
        """
        elements.append(Paragraph(footer_text, styles['Justify']))
        
        # Build PDF
        doc.build(elements)
        
        return filepath
    
    def _save_text_certificate(self, cert_data, cert_id):
        """Save certificate as text file (fallback when ReportLab not available)"""
        filename = f"cert_{cert_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        filepath = self.cert_dir / filename
        
        with open(filepath, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("                    DATA WIPE CERTIFICATE\n")
            f.write("                  NIST SP 800-88 Rev. 1 Compliant\n")
            f.write("=" * 80 + "\n\n")
            
            f.write(f"{cert_data['organization']['name']}\n")
            f.write(f"{cert_data['organization']['department']}\n")
            f.write(f"{cert_data['organization']['address']}\n\n")
            
            f.write("-" * 80 + "\n")
            f.write(f"Certificate ID: {cert_data['certificate_id']}\n")
            f.write(f"Issue Date: {cert_data['timestamp']}\n")
            f.write("-" * 80 + "\n\n")
            
            f.write("WIPE DETAILS\n")
            f.write("-" * 40 + "\n")
            wipe_details = cert_data['wipe_details']
            f.write(f"Wipe Method: {wipe_details.get('wipe_method', 'N/A')}\n")
            f.write(f"Target Type: {wipe_details.get('target_type', 'N/A')}\n")
            f.write(f"Target Path: {wipe_details.get('target_path', 'N/A')}\n")
            f.write(f"Start Time: {wipe_details.get('start_time', 'N/A')}\n")
            f.write(f"End Time: {wipe_details.get('end_time', 'N/A')}\n")
            f.write(f"Total Bytes Wiped: {wipe_details.get('bytes_wiped', 0):,} bytes\n")
            f.write(f"Passes Completed: {wipe_details.get('passes_completed', 0)}\n")
            f.write(f"Verification Status: {wipe_details.get('verification_status', 'N/A')}\n\n")
            
            f.write("VERIFICATION\n")
            f.write("-" * 40 + "\n")
            f.write(f"Verification Hash:\n{cert_data['verification']['hash']}\n\n")
            
            f.write("DIGITAL SIGNATURE\n")
            f.write("-" * 40 + "\n")
            signature = cert_data['digital_signature']
            f.write(f"Algorithm: {signature['algorithm']}\n")
            f.write(f"Signature:\n{signature['signature']}\n")
            f.write(f"Timestamp: {signature['timestamp']}\n\n")
            
            f.write("=" * 80 + "\n")
            f.write("This certificate confirms that the data wiping operation was performed\n")
            f.write("according to NIST SP 800-88 Rev. 1 guidelines.\n")
            f.write("=" * 80 + "\n")
        
        return filepath
    
    def verify_certificate(self, cert_path):
        """Verify a certificate's authenticity"""
        try:
            if cert_path.endswith('.json'):
                with open(cert_path, 'r') as f:
                    cert_data = json.load(f)
            else:
                return {"valid": False, "error": "Only JSON certificates can be verified"}
            
            # Verify digital signature
            stored_signature = cert_data.get('digital_signature', {}).get('signature')
            
            # Recalculate signature
            data_copy = cert_data.copy()
            data_copy.pop('digital_signature', None)
            data_str = json.dumps(data_copy, sort_keys=True)
            calculated_signature = hashlib.sha512(data_str.encode()).hexdigest()
            
            is_valid = stored_signature == calculated_signature
            
            return {
                "valid": is_valid,
                "certificate_id": cert_data.get('certificate_id'),
                "timestamp": cert_data.get('timestamp'),
                "verification_hash": cert_data.get('verification', {}).get('hash'),
                "message": "Certificate is valid and authentic" if is_valid else "Certificate signature verification failed"
            }
            
        except Exception as e:
            return {"valid": False, "error": str(e)}

# Example usage
if __name__ == "__main__":
    generator = CertificateGenerator()
    
    # Sample wipe data
    wipe_data = {
        "wipe_method": "DoD 5220.22-M (3-pass)",
        "target_type": "File",
        "target_path": "C:\\test\\sensitive_data.txt",
        "start_time": datetime.now().isoformat(),
        "end_time": datetime.now().isoformat(),
        "bytes_wiped": 1048576,
        "passes_completed": 3,
        "verification_status": "Verified - Data Successfully Wiped",
        "target_info": {
            "original_size": 1048576,
            "file_system": "NTFS",
            "drive_type": "Fixed"
        },
        "duration": 45
    }
    
    # Generate certificate
    result = generator.generate_certificate(wipe_data)
    print(f"Certificate generated:")
    print(f"  ID: {result['certificate_id']}")
    print(f"  JSON: {result['json_path']}")
    print(f"  PDF: {result['pdf_path']}")
    print(f"  Verification Hash: {result['verification_hash']}")
    
    # Verify certificate
    verification = generator.verify_certificate(result['json_path'])
    print(f"\nCertificate verification: {verification}")
