import Foundation
import Combine

enum FAQCategory: String, CaseIterable, Identifiable {
    case rto = "RTO"
    case panCard = "PAN Card"
    case marriage = "Marriage Registration"
    case birthCertificate = "Birth Certificate"
    case visa = "Visa"
    case passport = "Passport"

    var id: String { rawValue }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let category: FAQCategory
    let question: String
    let answer: String
}

class FAQsViewModel: ObservableObject {
    @Published var selectedCategory: FAQCategory = .rto

    let topTitle: String = "frequeantly Asked Questions"
    let sectionTitle: String = "Questions"
    let headingTitle: String = "Frequently Asked Questions"

    var filteredFAQs: [FAQItem] {
        faqs.filter { $0.category == selectedCategory }
    }

    let faqs: [FAQItem] = [
        FAQItem(
            category: .rto,
            question: "How secure is my documents with Itzeazy ?",
            answer: "We take utmost care to ensure safety and security of the documents. We value your privacy and sincerely concern about the trust which you bestowed on us."
        ),
        FAQItem(category: .rto, question: "How Itzeazy is different from typical agents ?", answer: "Itzeazy is an organised company having operations in 10 cities of India. It has well defined processes. Your money and documents are absolutely safe with Itzeazy. Services are door-step . Hassle free service of Itzeazy is total peace of mind."),
        FAQItem(category: .rto, question: "Will I get refund in case service is not delivered ?", answer: "Yes. You are entitled to get refund in case of non delivery of services . Please refer our refund policy for more details."),
        FAQItem(category: .rto, question: "After making payment where can I check the payment status ?", answer: "Payment details can be checked in my payment."),
        FAQItem(category: .rto, question: "What is the need for document verification?", answer: "To process your documents in Govt. office document has to be completed in all respect . Inomplete document results into delay of the work. To avoid this delay, Itzeazy takes utmost care and does document verification properly before collection of the original documents and required forms."),
        FAQItem(category: .rto, question: "Will the documents collected from my home? The services of Itzeazy is doorstep. We have fre", answer: "The services of Itzeazy is doorstep. We have free document collection facility within 7 km radius from the concerned office. In case distance is more than 7 kms from the concerned office, the cost of extra distance should be borne by the client. The extra cost will be calculated @ 15 Rs. per km. This pickup facility is strictly within the same city where work is to be done.  For example, if vehicle is registered at Electronic city RTO and your residence is 30 km away from Electronic city RTO, the extra cost of distance which is 30-7 = 23*15 i.e. Rs. 345 , you will have to bear.  In case you are in a city other than the city where work is to be done, you need to courier documents to our office in the city where work is to done.  For example, if your vehicle is registered in Bangalore and you are currently in Pune then you need to send documents to our Bangalore office by courier."),
        FAQItem(category: .rto, question: "How I will get my documents back after the work completion ?", answer: "Itzeazy will send back documents after work completion to your address within India through standard courier services. Outside India delivery cost should be borne by the client.  We can also arrange priority and quick delivery service such as bluedart, dunzo, borzo on actual cost basis to the client."),
        FAQItem(category: .rto, question: "I want to apply for car NOC which is registered in Bangalore . Currently I am in Pune. Will my documents collected from Pune ?", answer: "Right now we collect document from the same city only where work has to be done. Like if vehcile is registered in Bangalore we can collect documents from Bangalore only. If you are in some other city , you will have to send documents to our Bangalore office through courier. However Delhi- NCR is an exception. If work is to be done in Delhi and document has to be collected from Ghaziabad, that is possible."),
        FAQItem(category: .rto, question: "How can we trust Itzeazy?", answer: "Itzeazy is 5 year old startup having services in 10 cities of India. And we have reputed clients like Uber, Hindustan lever, Bank of America, Quikr, Olx, Cars24"),
        FAQItem(category: .rto, question: "Govt. fees is very less, however Itzeazy charges seems to be little higher. ?", answer: "Services of Itzeazy is kind of premium concierge service. We save your time and and provides hassle free door step service. Do proper documentation so that your work gets done. Also we have office , staffs to do it smoothly . Obviuosly it has cost. You can do it yourself too but for that you will have to visit govt office multiple time."),
        FAQItem(category: .rto, question: "How my documents will be dispatched ?", answer: "Once you get notification from our side that your work has been completed, go to current status , make the balance payment if anything is dues, share address for dispatch. documents will be dispatched within 7 working days."),
        FAQItem(category: .rto, question: "For vehicle NOC presence of registered owner and vehicle required or not in Noida and Ghaziabad ?", answer: "Yes, for vehicle NOC presence of registered owner and vehicle both is required in Noida and Ghaziabad."),
        FAQItem(category: .rto, question: "Presence of registered owner is required or not for RTO services in Noida and ghaziabad ?", answer: "Yes, prsence of registered owner is required for all kinds of RTO process in Noida and Ghaziabad."),
        FAQItem(category: .rto, question: "In case of duplicate RC process presence of registered owner is required in which cities?", answer: "For duplicate RC process, presence of registered owner is required in Bangalore, Chennai, Mumbai, Pune, Chennai, Hyderabad, Noida, Ghaziabad."),
        FAQItem(category: .rto, question: "For RTO process presence of registered owner is required or not ?", answer: "Presence of registered owner is required for all RTO process except NOC which can be done without owner's presence ."),
        FAQItem(category: .rto, question: "I want to apply for re-registration of vehicle. How much road tax I will have to pay?", answer: "To calculate road tax , in the menu in the home page go to tools , then road tax calculator."),
//        FAQItem(category: .panCard, question: "PAN card related question will appear here.", answer: ""),
//        FAQItem(category: .marriage, question: "Marriage registration related question will appear here.", answer: ""),
//        FAQItem(category: .birthCertificate, question: "Birth certificate related question will appear here.", answer: ""),
//        FAQItem(category: .visa, question: "Visa related question will appear here.", answer: ""),
//        FAQItem(category: .passport, question: "Passport related question will appear here.", answer: "")
    ]
}
