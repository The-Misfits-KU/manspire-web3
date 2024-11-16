// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalPersona {
    struct User {
        address wallet;
        string name;
        string bio;
        string profileImage; 
        address[] followers;
        address[] following;
    }

    struct Post {
        string title;
        string body;
        string files;
        string featuredImage;
        address userId;
        uint256 id; 
    }

    struct PostWithAuthor {
        Post post;
        User author;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    address[] public userAddresses;
    mapping(address => uint256[]) public userPosts; // Store post IDs for each user

    uint256 public postCounter; // Counter for incremental post IDs

    event UserRegistered(address indexed wallet);
    event PostCreated(uint256 indexed postId, address indexed userId);

    function registerUser(string memory _name, string memory _bio, string memory _profileImage) public {
        require(bytes(users[msg.sender].name).length == 0, "User already registered.");

        users[msg.sender] = User({
            wallet: msg.sender,
            name: _name,
            bio: _bio,
            profileImage: _profileImage,
            followers: new address[](0),
            following: new address[](0)
        });

        userAddresses.push(msg.sender);

        emit UserRegistered(msg.sender);
    }

    function createPost(
        string memory _title, 
        string memory _body, 
        string memory _files, 
        string memory _featuredImage
    ) public {
        require(bytes(users[msg.sender].name).length != 0, "User not registered.");
        require(bytes(_title).length > 0, "Post title is required.");
        require(bytes(_body).length > 0, "Post body is required.");

        postCounter++; // Increment the post counter

        posts[postCounter] = Post({
            title: _title,
            body: _body,
            files: bytes(_files).length > 0 ? _files : "",
            featuredImage: bytes(_featuredImage).length > 0 ? _featuredImage : "",
            userId: msg.sender,
            id: postCounter
        });

        userPosts[msg.sender].push(postCounter);

        emit PostCreated(postCounter, msg.sender);
    }

    function followUser(address _userToFollow) public {
        require(bytes(users[msg.sender].name).length != 0, "User not registered.");
        require(bytes(users[_userToFollow].name).length != 0, "User to follow not registered.");
        require(msg.sender != _userToFollow, "Cannot follow yourself.");

        // Check if already following
        bool isFollowing = false;
        uint256 index = 0;

        for (uint256 i = 0; i < users[msg.sender].following.length; i++) {
            if (users[msg.sender].following[i] == _userToFollow) {
                isFollowing = true;
                index = i;
                break;
            }
        }

        if (isFollowing) {
            // Unfollow logic: Remove from following and followers arrays
            users[msg.sender].following[index] = users[msg.sender].following[users[msg.sender].following.length - 1];
            users[msg.sender].following.pop();

            for (uint256 i = 0; i < users[_userToFollow].followers.length; i++) {
                if (users[_userToFollow].followers[i] == msg.sender) {
                    users[_userToFollow].followers[i] = users[_userToFollow].followers[users[_userToFollow].followers.length - 1];
                    users[_userToFollow].followers.pop();
                    break;
                }
            }
        } else {
            // Follow logic
            users[msg.sender].following.push(_userToFollow);
            users[_userToFollow].followers.push(msg.sender);
        }
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    function getFollowers(address _user) public view returns (address[] memory) {
        return users[_user].followers;
    }

    function getFollowing(address _user) public view returns (address[] memory) {
        return users[_user].following;
    }

    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }

    function getPostById(uint256 _postId) public view returns (Post memory) {
        require(posts[_postId].id != 0, "Post does not exist.");
        return posts[_postId];
    }

    function getPostWithAuthorById(uint256 _postId) public view returns (PostWithAuthor memory) {
        require(posts[_postId].id != 0, "Post does not exist.");
        Post memory post = posts[_postId];
        User memory author = users[post.userId];
        return PostWithAuthor({post: post, author: author});
    }

    function getPostsWithAuthorsByUser(address _user) public view returns (PostWithAuthor[] memory) {
        uint256[] memory postIds = userPosts[_user];
        PostWithAuthor[] memory usersPosts = new PostWithAuthor[](postIds.length);

        for (uint256 i = 0; i < postIds.length; i++) {
            Post memory post = posts[postIds[i]];
            User memory author = users[post.userId];
            usersPosts[i] = PostWithAuthor({post: post, author: author});
        }

        return usersPosts;
    }

    function getUserFeedWithAuthors(address _user) public view returns (PostWithAuthor[] memory) {
        address[] memory following = users[_user].following;
        uint256 totalPosts = 0;

        for (uint256 i = 0; i < following.length; i++) {
            totalPosts += userPosts[following[i]].length;
        }

        PostWithAuthor[] memory feed = new PostWithAuthor[](totalPosts);
        uint256 index = 0;

        for (uint256 i = 0; i < following.length; i++) {
            uint256[] memory postIds = userPosts[following[i]];
            for (uint256 j = 0; j < postIds.length; j++) {
                Post memory post = posts[postIds[j]];
                User memory author = users[post.userId];
                feed[index] = PostWithAuthor({post: post, author: author});
                index++;
            }
        }

        return feed;
    }

    function getUsersToFollow() public view returns (address[] memory) {
        require(bytes(users[msg.sender].name).length != 0, "User not registered.");

        uint256 potentialCount = 0;

        // First, count how many users are eligible to be followed
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] != msg.sender && !_isFollowing(msg.sender, userAddresses[i])) {
                potentialCount++;
            }
        }

        // Create an array of the appropriate size
        address[] memory toFollow = new address[](potentialCount);
        uint256 index = 0;

        // Populate the array
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] != msg.sender && !_isFollowing(msg.sender, userAddresses[i])) {
                toFollow[index] = userAddresses[i];
                index++;
            }
        }

        return toFollow;
    }

    function _isFollowing(address user, address target) internal view returns (bool) {
        for (uint256 i = 0; i < users[user].following.length; i++) {
            if (users[user].following[i] == target) {
                return true;
            }
        }
        return false;
    }
}
