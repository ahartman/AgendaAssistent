//
//  ContactsModel.swift
//  AgendaAssistent
//
//  Created by André Hartman on 15/12/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//
import Contacts
import MapKit

class ContactModel {
    func updatePatientsFromContacts(patientsNoGeo: [PatientInfo.Patient], contacts: [CNContact]) {
        var localPatients = [PatientInfo.Patient]()

        for patient in patientsNoGeo {
            let contact = contacts.first(where: {
                patient.patientName.localizedStandardContains($0.givenName) &&
                    patient.patientName.localizedStandardContains($0.familyName)

            })
            if let geoContact = contact {
                if geoContact.previousFamilyName.contains(":") {
                    let geo = geoContact.previousFamilyName.components(separatedBy: ":")
                    localPatients.append(
                        PatientInfo.Patient(
                            id: patient.id,
                            patientName: patient.patientName,
                            patientLatitude: Double(geo[0]),
                            patientLongitude: Double(geo[1])
                        )
                    )
                }
            }
        }
        DBModel().updateDBWithGeo(patients: localPatients)
        print("\(localPatients.count) patients updated from Contacts")
    }

    func updatePatientsContactsFromGeocoder(patientsNoGeo: [PatientInfo.Patient], contacts: [CNContact]) async {
        var waiting = false

        var patients = patientsNoGeo
        while patients.count > 0 {
            let to = min(44, patients.count - 1)
            for patient in Array(patients[...to]) {
                let contact = contacts.first(where: {
                    patient.patientName.localizedStandardContains($0.givenName) &&
                        patient.patientName.localizedStandardContains($0.familyName)

                })
                if let geoContact = contact {
                    if let postalAddress = geoContact.postalAddresses.first {
                        do {
                            print("Finding: \(patient.patientName)")
                            let placemarks = try await CLGeocoder().geocodePostalAddress(postalAddress.value)
                            if let location = placemarks.first?.location {
                                print("Found: \(patient.patientName), \(location.coordinate.latitude), \(location.coordinate.longitude)")
                                waiting = true
                                let tempPatient = [
                                    PatientInfo.Patient(
                                        id: patient.id,
                                        patientName: patient.patientName,
                                        patientLatitude: location.coordinate.latitude,
                                        patientLongitude: location.coordinate.longitude
                                    ),
                                ]
                                DBModel().updateDBWithGeo(patients: tempPatient)

                                let tempContact = [[
                                    geoContact.identifier,
                                    "\(location.coordinate.latitude):\(location.coordinate.longitude)",
                                ]]
                                saveGeocodes(contacts: contacts, geoFound: tempContact)
                            }
                        } catch {
                            if debugPrint { print("CLGeocoder fout (adres niet gevonden): \(error), \(postalAddress)") }
                        }
                    }
                }
            }
            if waiting {
                do {
                    try await Task.sleep(for: .seconds(30))
                } catch {
                    fatalError("getNoGeoPatients: \(error)")
                }
            }
            waiting = false
            patients = Array(patients.dropFirst(to + 1))
        }
    }

    func saveGeocodes(contacts: [CNContact], geoFound: [[String]]) {
        if debugPrint { print("saveGeo", geoFound) }
        let store = CNContactStore()
        let saveRequest = CNSaveRequest()

        for geo in geoFound {
            let geoContact = contacts.filter { $0.identifier == geo[0] }
            let mutableContact = geoContact[0].mutableCopy() as! CNMutableContact
            mutableContact.previousFamilyName = geo[1]
            saveRequest.update(mutableContact)
        }
        do {
            try store.execute(saveRequest)
        } catch {
            print("Error in saveGeo: \(error)")
        }
    }

    public func getContacts() -> [CNContact] {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authStatus {
        case .restricted:
            print("User cannot grant permission, e.g. parental controls in force.")
            exit(1)
        case .denied:
            print("User has explicitly denied permission.")
            print("They have to grant it via Preferences app if they change their mind.")
            exit(1)
        case .notDetermined:
            print("You need to request authorization via the API now.")
        case .authorized:
            _ = 1
        // print("You are authorized to Contacts.")
        default:
            print("Unknown issue in switch")
        }

        let store = CNContactStore()
        if authStatus == .notDetermined {
            store.requestAccess(for: CNEntityType.contacts) { success, error in
                if !success {
                    print("Not authorized to access contacts. Error = \(String(describing: error))")
                    exit(1)
                }
            }
        }

        var contacts = [CNContact]()
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPreviousFamilyNameKey,
            CNContactPostalAddressesKey,
        ] as [any CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = CNContactSortOrder.userDefault

        do {
            try store.enumerateContacts(with: request) {
                contact, _ in
                contacts.append(contact)
            }
        } catch {
            print("Error fetching results for Contacts container")
        }
        return contacts
    }
}
