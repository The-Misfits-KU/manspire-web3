// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MentalHealthPlatform {
    enum SessionState { Created, Completed, Refunded }

    struct User {
        string nickname;
        bool isRegistered;
    }

    struct Therapist {
        string name;
        string specialization;
        uint256 pricePerSession;
        bool isRegistered;
    }

    struct Session {
        address therapist;
        address user;
        uint256 sessionFee;
        uint256 sessionTime;
        string sessionLink;
        SessionState state;
    }

    mapping(address => User) public users;
    mapping(address => Therapist) public therapists;
    Session[] public sessions;

    address[] public therapistAddresses;
    address[] public userAddresses;

    event UserRegistered(address indexed user, string nickname);
    event TherapistRegistered(address indexed therapist, string name, string specialization);
    event SessionCreated(uint256 indexed sessionId, address indexed therapist, address indexed user, uint256 sessionFee);
    event SessionCompleted(uint256 indexed sessionId);
    event SessionRefunded(uint256 indexed sessionId);

    // Register a user
    function registerUser(string memory _nickname) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(!therapists[msg.sender].isRegistered, "Cannot register as both user and therapist");

        users[msg.sender] = User({nickname: _nickname, isRegistered: true});
        userAddresses.push(msg.sender);

        emit UserRegistered(msg.sender, _nickname);
    }

    // Register a therapist
    function registerTherapist(
        string memory _name,
        string memory _specialization,
        uint256 _pricePerSession
    ) public {
        require(!therapists[msg.sender].isRegistered, "Therapist already registered");
        require(!users[msg.sender].isRegistered, "Cannot register as both user and therapist");

        therapists[msg.sender] = Therapist({
            name: _name,
            specialization: _specialization,
            pricePerSession: _pricePerSession,
            isRegistered: true
        });
        therapistAddresses.push(msg.sender);

        emit TherapistRegistered(msg.sender, _name, _specialization);
    }

    // Create a session
    function createSession(
        address _therapist,
        uint256 _sessionTime,
        string memory _sessionLink
    ) public payable {
        require(users[msg.sender].isRegistered, "User not registered");
        require(therapists[_therapist].isRegistered, "Therapist not registered");
        require(msg.value == therapists[_therapist].pricePerSession, "Incorrect session fee");

        uint256 sessionId = sessions.length;

        sessions.push(
            Session({
                therapist: _therapist,
                user: msg.sender,
                sessionFee: msg.value,
                sessionTime: _sessionTime,
                sessionLink: _sessionLink,
                state: SessionState.Created
            })
        );

        emit SessionCreated(sessionId, _therapist, msg.sender, msg.value);
    }

    // Complete a session
    function completeSession(uint256 _sessionId) public {
        Session storage session = sessions[_sessionId];
        require(session.therapist == msg.sender, "Not authorized");
        require(session.state == SessionState.Created, "Session not active");

        session.state = SessionState.Completed;

        // Pay the therapist
        payable(session.therapist).transfer(session.sessionFee);

        emit SessionCompleted(_sessionId);
    }

    // Request a refund
    function refundSession(uint256 _sessionId) public {
        Session storage session = sessions[_sessionId];
        require(session.user == msg.sender, "Not authorized");
        require(session.state == SessionState.Created, "Session not refundable");
        require(block.timestamp < session.sessionTime, "Session already occurred");

        session.state = SessionState.Refunded;

        // Refund the user
        payable(session.user).transfer(session.sessionFee);

        emit SessionRefunded(_sessionId);
    }

    // Retrieve all sessions
    function getAllSessions() public view returns (Session[] memory) {
        return sessions;
    }

    // Retrieve sessions by user
    function getSessionsByUser(address _user) public view returns (Session[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < sessions.length; i++) {
            if (sessions[i].user == _user) {
                count++;
            }
        }

        Session[] memory userSessions = new Session[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < sessions.length; i++) {
            if (sessions[i].user == _user) {
                userSessions[index] = sessions[i];
                index++;
            }
        }

        return userSessions;
    }

    // Retrieve all users
    function getAllUsers() public view returns (User[] memory) {
        User[] memory allUsers = new User[](userAddresses.length);
        for (uint256 i = 0; i < userAddresses.length; i++) {
            allUsers[i] = users[userAddresses[i]];
        }
        return allUsers;
    }

    // Get all therapist
    function getAllTherapists() public view returns (Therapist[] memory) {
        Therapist[] memory allTherapists = new Therapist[](therapistAddresses.length);
        for (uint256 i = 0; i < therapistAddresses.length; i++) {
            allTherapists[i] = therapists[therapistAddresses[i]];
        }
        return allTherapists;
    }

    // Retrieve sessions by therapist
    function getSessionsByTherapist(address _therapist) public view returns (Session[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < sessions.length; i++) {
            if (sessions[i].therapist == _therapist) {
                count++;
            }
        }

        Session[] memory therapistSessions = new Session[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < sessions.length; i++) {
            if (sessions[i].therapist == _therapist) {
                therapistSessions[index] = sessions[i];
                index++;
            }
        }

        return therapistSessions;
    }

    // Retrieve session by ID
    function getSessionById(uint256 _sessionId) public view returns (Session memory) {
        require(_sessionId < sessions.length, "Session ID out of range");
        return sessions[_sessionId];
    }
}
