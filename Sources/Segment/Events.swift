//
//  Events.swift
//  Segment
//
//  Created by Cody Garvin on 11/30/20.
//

import Foundation

// MARK: - Typed Event Signatures

extension Analytics {
    // make a note in the docs on this that we removed the old "options" property
    // and they need to write a middleware/enrichment now.
    // the objc version should accomodate them if it's really needed.
    
    /// Tracks an event performed by a user, including some additional event properties.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - properties: Properties specific to the named event. For example, an event with
    ///     the name 'Purchased a Shirt' might have properties like revenue or size.
    public func track<P: Codable>(name: String, properties: P?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = TrackEvent(event: name, properties: jsonProperties)
                process(incomingEvent: event)
            } else {
                let event = TrackEvent(event: name, properties: nil)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Tracks an event performed by a user.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    public func track(name: String) {
        track(name: name, properties: nil as TrackEvent?)
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user. If you don't have a userId
    ///     but want to record traits, just pass traits into the event and they will be associated
    ///     with the anonymousId of that user.  In the case when user logs out, make sure to
    ///     call ``reset()`` to clear the user's identity info. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see
    ///      https://segment.io/libraries/ios#ids
    /// - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func identify<T: Codable>(userId: String, traits: T?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: jsonTraits))
                let event = IdentifyEvent(userId: userId, traits: jsonTraits)
                process(incomingEvent: event)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyEvent(userId: userId, traits: nil)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    public func identify<T: Codable>(traits: T) {
        do {
            let jsonTraits = try JSON(with: traits)
            store.dispatch(action: UserInfo.SetTraitsAction(traits: jsonTraits))
            let event = IdentifyEvent(traits: jsonTraits)
            process(incomingEvent: event)
        } catch {
            reportInternalError(error, fatal: true)
        }
    }

    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user.
    ///     For more information on how we generate the UUID and Apple's policies on IDs, see
    ///     https://segment.io/libraries/ios#ids
    /// In the case when user logs out, make sure to call ``reset()`` to clear user's identity info.
    public func identify(userId: String) {
        let event = IdentifyEvent(userId: userId, traits: nil)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: userId))
        process(incomingEvent: event)
    }
    
    public func screen<P: Codable>(title: String, category: String? = nil, properties: P?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = ScreenEvent(title: title, category: category, properties: jsonProperties)
                process(incomingEvent: event)
            } else {
                let event = ScreenEvent(title: title, category: category)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    public func screen(title: String, category: String? = nil) {
        screen(title: title, category: category, properties: nil as ScreenEvent?)
    }

    public func group<T: Codable>(groupId: String, traits: T?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                let event = GroupEvent(groupId: groupId, traits: jsonTraits)
                process(incomingEvent: event)
            } else {
                let event = GroupEvent(groupId: groupId)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    public func group(groupId: String) {
        group(groupId: groupId, traits: nil as GroupEvent?)
    }
    
    public func alias(newId: String) {
        let event = AliasEvent(newId: newId, previousId: self.userId)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: newId))
        process(incomingEvent: event)
    }
}

// MARK: - Untyped Event Signatures

extension Analytics {
    /// Tracks an event performed by a user, including some additional event properties.
    /// - Parameters:
    ///   - messageId: The unique identifier for the TrackEvent
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - properties: A dictionary or properties specific to the named event.
    ///     For example, an event with the name 'Purchased a Shirt' might have properties
    ///     like revenue or size.
    public func track(messageId: String, name: String, properties: [String: Any]? = nil) {
        var props: JSON? = nil
        if let properties = properties {
            do {
                props = try JSON(properties)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        let event = TrackEvent(messageId: messageId, event: name, properties: props)
        process(incomingEvent: event)
    }

    /// Tracks an event performed by a user, including some additional event properties.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - properties: A dictionary or properties specific to the named event.
    ///     For example, an event with the name 'Purchased a Shirt' might have properties
    ///     like revenue or size.
    public func track(name: String, properties: [String: Any]? = nil) {
        var props: JSON? = nil
        if let properties = properties {
            do {
                props = try JSON(properties)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        let event = TrackEvent(event: name, properties: props)
        process(incomingEvent: event)
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user. If you don't have a userId
    ///     but want to record traits, just pass traits into the event and they will be associated
    ///     with the anonymousId of that user.  In the case when user logs out, make sure to
    ///     call ``reset()`` to clear the user's identity info. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see
    ///      https://segment.io/libraries/ios#ids
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    /// In the case when user logs out, make sure to call ``reset()`` to clear user's identity info.
    public func identify(userId: String, traits: [String: Any]? = nil) {
        do {
            if let traits = traits {
                let traits = try JSON(traits as Any)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: traits))
                let event = IdentifyEvent(userId: userId, traits: traits)
                process(incomingEvent: event)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyEvent(userId: userId, traits: nil)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Track a screen change with a title, category and other properties.
    /// - Parameters:
    ///   - screenTitle: The title of the screen being tracked.
    ///   - category: A category to the type of screen if it applies.
    ///   - properties: Any extra metadata associated with the screen. e.g. method of access, size, etc.
    public func screen(title: String, category: String? = nil, properties: [String: Any]? = nil) {
        // if properties is nil, this is the event that'll get used.
        var event = ScreenEvent(title: title, category: category, properties: nil)
        // if we have properties, get a new one rolling.
        if let properties = properties {
            do {
                let jsonProperties = try JSON(properties)
                event = ScreenEvent(title: title, category: category, properties: jsonProperties)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        process(incomingEvent: event)
    }
    
    /// Associate a user with a group such as a company, organization, project, etc.
    /// - Parameters:
    ///   - groupId: A unique identifier for the group identification in your system.
    ///   - traits: Traits of the group you may be interested in such as email, phone or name.
    public func group(groupId: String, traits: [String: Any]?) {
        var event = GroupEvent(groupId: groupId)
        if let traits = traits {
            do {
                let jsonTraits = try JSON(traits)
                event = GroupEvent(groupId: groupId, traits: jsonTraits)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        process(incomingEvent: event)
    }
}

// MARK: - Enrichment event signatures

extension Analytics {
    // Tracks an event performed by a user, including some additional event properties.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - properties: Properties specific to the named event. For example, an event with
    ///     the name 'Purchased a Shirt' might have properties like revenue or size.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func track<P: Codable>(name: String, properties: P?, enrichments: [EnrichmentClosure]?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = TrackEvent(event: name, properties: jsonProperties)
                process(incomingEvent: event, enrichments: enrichments)
            } else {
                let event = TrackEvent(event: name, properties: nil)
                process(incomingEvent: event, enrichments: enrichments)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Tracks an event performed by a user.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func track(name: String, enrichments: [EnrichmentClosure]?) {
        track(name: name, properties: nil as TrackEvent?, enrichments: enrichments)
    }
    
    /// Tracks an event performed by a user, including some additional event properties.
    /// - Parameters:
    ///   - name: Name of the action, e.g., 'Purchased a T-Shirt'
    ///   - properties: A dictionary or properties specific to the named event.
    ///     For example, an event with the name 'Purchased a Shirt' might have properties
    ///     like revenue or size.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func track(name: String, properties: [String: Any]?, enrichments: [EnrichmentClosure]?) {
        var props: JSON? = nil
        if let properties = properties {
            do {
                props = try JSON(properties)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        let event = TrackEvent(event: name, properties: props)
        process(incomingEvent: event, enrichments: enrichments)
    }

    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user. If you don't have a userId
    ///     but want to record traits, just pass traits into the event and they will be associated
    ///     with the anonymousId of that user.  In the case when user logs out, make sure to
    ///     call ``reset()`` to clear the user's identity info. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see
    ///      https://segment.io/libraries/ios#ids
    ///  - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    ///  - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func identify<T: Codable>(userId: String, traits: T?, enrichments: [EnrichmentClosure]?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: jsonTraits))
                let event = IdentifyEvent(userId: userId, traits: jsonTraits)
                process(incomingEvent: event, enrichments: enrichments)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyEvent(userId: userId, traits: nil)
                process(incomingEvent: event, enrichments: enrichments)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func identify<T: Codable>(traits: T, enrichments: [EnrichmentClosure]?) {
        do {
            let jsonTraits = try JSON(with: traits)
            store.dispatch(action: UserInfo.SetTraitsAction(traits: jsonTraits))
            let event = IdentifyEvent(traits: jsonTraits)
            process(incomingEvent: event, enrichments: enrichments)
        } catch {
            reportInternalError(error, fatal: true)
        }
    }

    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user.
    ///     For more information on how we generate the UUID and Apple's policies on IDs, see
    ///     https://segment.io/libraries/ios#ids
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    /// In the case when user logs out, make sure to call ``reset()`` to clear user's identity info.
    public func identify(userId: String, enrichments: [EnrichmentClosure]?) {
        let event = IdentifyEvent(userId: userId, traits: nil)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: userId))
        process(incomingEvent: event, enrichments: enrichments)
    }

    /// Associate a user with their unique ID and record traits about them.
    /// - Parameters:
    ///   - userId: A database ID for this user. If you don't have a userId
    ///     but want to record traits, just pass traits into the event and they will be associated
    ///     with the anonymousId of that user.  In the case when user logs out, make sure to
    ///     call ``reset()`` to clear the user's identity info. For more information on how we
    ///     generate the UUID and Apple's policies on IDs, see
    ///      https://segment.io/libraries/ios#ids
    ///   - traits: A dictionary of traits you know about the user. Things like: email, name, plan, etc.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    /// In the case when user logs out, make sure to call ``reset()`` to clear user's identity info.
    public func identify(userId: String, traits: [String: Any]? = nil, enrichments: [EnrichmentClosure]?) {
        do {
            if let traits = traits {
                let traits = try JSON(traits as Any)
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: traits))
                let event = IdentifyEvent(userId: userId, traits: traits)
                process(incomingEvent: event, enrichments: enrichments)
            } else {
                store.dispatch(action: UserInfo.SetUserIdAndTraitsAction(userId: userId, traits: nil))
                let event = IdentifyEvent(userId: userId, traits: nil)
                process(incomingEvent: event, enrichments: enrichments)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Track a screen change with a title, category and other properties.
    /// - Parameters:
    ///   - screenTitle: The title of the screen being tracked.
    ///   - category: A category to the type of screen if it applies.
    ///   - properties: Any extra metadata associated with the screen. e.g. method of access, size, etc.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func screen<P: Codable>(title: String, category: String? = nil, properties: P?, enrichments: [EnrichmentClosure]?) {
        do {
            if let properties = properties {
                let jsonProperties = try JSON(with: properties)
                let event = ScreenEvent(title: title, category: category, properties: jsonProperties)
                process(incomingEvent: event, enrichments: enrichments)
            } else {
                let event = ScreenEvent(title: title, category: category)
                process(incomingEvent: event, enrichments: enrichments)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    /// Track a screen change with a title, category and other properties.
    /// - Parameters:
    ///   - screenTitle: The title of the screen being tracked.
    ///   - category: A category to the type of screen if it applies.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func screen(title: String, category: String? = nil, enrichments: [EnrichmentClosure]?) {
        screen(title: title, category: category, properties: nil as ScreenEvent?, enrichments: enrichments)
    }
    
    /// Track a screen change with a title, category and other properties.
    /// - Parameters:
    ///   - screenTitle: The title of the screen being tracked.
    ///   - category: A category to the type of screen if it applies.
    ///   - properties: Any extra metadata associated with the screen. e.g. method of access, size, etc.
    ///   - enrichments: Enrichments to be applied to this specific event only, or `nil` for none.
    public func screen(title: String, category: String? = nil, properties: [String: Any]?, enrichments: [EnrichmentClosure]?) {
        // if properties is nil, this is the event that'll get used.
        var event = ScreenEvent(title: title, category: category, properties: nil)
        // if we have properties, get a new one rolling.
        if let properties = properties {
            do {
                let jsonProperties = try JSON(properties)
                event = ScreenEvent(title: title, category: category, properties: jsonProperties)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        process(incomingEvent: event, enrichments: enrichments)
    }
    
    public func group<T: Codable>(groupId: String, traits: T?, enrichments: [EnrichmentClosure]?) {
        do {
            if let traits = traits {
                let jsonTraits = try JSON(with: traits)
                let event = GroupEvent(groupId: groupId, traits: jsonTraits)
                process(incomingEvent: event)
            } else {
                let event = GroupEvent(groupId: groupId)
                process(incomingEvent: event)
            }
        } catch {
            reportInternalError(error, fatal: true)
        }
    }
    
    public func group(groupId: String, enrichments: [EnrichmentClosure]?) {
        group(groupId: groupId, traits: nil as GroupEvent?, enrichments: enrichments)
    }
    
    /// Associate a user with a group such as a company, organization, project, etc.
    /// - Parameters:
    ///   - groupId: A unique identifier for the group identification in your system.
    ///   - traits: Traits of the group you may be interested in such as email, phone or name.
    public func group(groupId: String, traits: [String: Any]?, enrichments: [EnrichmentClosure]?) {
        var event = GroupEvent(groupId: groupId)
        if let traits = traits {
            do {
                let jsonTraits = try JSON(traits)
                event = GroupEvent(groupId: groupId, traits: jsonTraits)
            } catch {
                reportInternalError(error, fatal: true)
            }
        }
        process(incomingEvent: event, enrichments: enrichments)
    }
    
    public func alias(newId: String, enrichments: [EnrichmentClosure]?) {
        let event = AliasEvent(newId: newId, previousId: self.userId)
        store.dispatch(action: UserInfo.SetUserIdAction(userId: newId))
        process(incomingEvent: event, enrichments: enrichments)
    }
}
