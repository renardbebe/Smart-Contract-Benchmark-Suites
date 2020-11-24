 
     
    function writePost(uint256 _id, uint256 _value, string _content, string _media) public onlyWednesdays repayable whenNotPaused whenNotSuspended whenTimeElapsedPost {
        require(amountForPost == _value);
        require(bytes(_content).length > 0 || bytes(_media).length > 0);
        _id = uint256(keccak256(_id, now, blockhash(block.number - 1), block.coinbase));
         
        require(posts[_id].id != _id);
         
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            emit PostContent(_id, _content, _media);
            Post memory post = Post(_id, msg.sender, 0, 0, now, 0);
            userPosts[msg.sender].push(_id);
            posts[_id] = post;
            postIds.push(_id);
            postTime[msg.sender] = now;
        } else {
            revert();
        }
    }

    function likePost(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumToLikePost);
         
        if (posts[_id].id == _id) {
             
            require(posts[_id].poster != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, posts[_id].poster, _value)) {
                posts[_id].value += _value;
                posts[_id].likes++;
            } else {
                revert();
            }
        }
    }

    function reportPost(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(hasElapsedReport());
         
        if (posts[_id].id == _id) {
             
            require(posts[_id].poster != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
                posts[_id].reportCount++;
                reportTime[msg.sender] = now;
            } else {
                revert();
            }
        }
    }

     
    function deleteUserPost(address _user, uint256 _id) public onlyOwner {
        for(uint i = 0; i < userPosts[_user].length; i++) {
            if(userPosts[_user][i] == _id){
                delete userPosts[_user][i];
            }
        }
    }

     
    function deletePublicPost(uint256 _id) public onlyOwner {
        if(posts[_id].id == _id){
            delete posts[_id];
        }
    }

    function deleteIdFromPostIds(uint256 _id) public onlyOwner  {
        uint256 indexToDelete;
        for(uint i = 0; i < postIds.length; i++) {
            if(postIds[i] == _id) {
                indexToDelete = i;
            }
        }
        delete postIds[indexToDelete];
    }
     
    function deleteAllPosts() public onlyOwner {
        deleteAllPosts(postIds.length);
    }

     
    function deleteAllPosts(uint256 _amountToDelete) public onlyOwner {
        for(uint i = 0; i < _amountToDelete; i++) {
            address poster = posts[postIds[i]].poster;
            deleteUserPost(poster, posts[postIds[i]].id);
            deletePublicPost(posts[postIds[i]].id);
            deleteIdFromPostIds(posts[postIds[i]].id);
        }
    }

     
    function deletePost(address _user, uint256 _id) public onlyOwner {
        deleteUserPost(_user, _id);
        deletePublicPost(_id);
        deleteIdFromPostIds(_id);
    }

     
     
    function writeComment(uint256 _id, uint256 _parentId, uint256 _value, string _content, string _media) public onlyWednesdays repayable whenNotPaused whenNotSuspended whenTimeElapsedComment {
        require(amountForComment == _value);
        require(bytes(_content).length > 0 || bytes(_media).length > 0);
        _id = uint256(keccak256(_id, now, blockhash(block.number - 1), block.coinbase));
         
        require(posts[_parentId].id == _parentId);
        require(comments[_id].id != _id);
         
        if (wednesdayCoin.transferFrom(msg.sender, posts[_parentId].poster, _value)) {
            emit CommentContent(_id, _content, _media);
            Comment memory comment = Comment(_id, _parentId, msg.sender, 0, 0, now, 0);
            userComments[msg.sender].push(_id);
            comments[_id] = comment;
            postComments[_parentId].push(_id);
            commentTime[msg.sender] = now;
        } else {
            revert();
        }
    }

    function likeComment(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumToLikeComment);
         
        if (comments[_id].id == _id) {
             
            require(comments[_id].commenter != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, comments[_id].commenter, _value)) {
                comments[_id].value += _value;
                comments[_id].likes++;
            } else {
                revert();
            }
        }
    }

    function reportComment(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(hasElapsedReport());
         
        if (comments[_id].id == _id) {
             
            require(comments[_id].commenter != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
                comments[_id].reportCount++;
                reportTime[msg.sender] = now;
            } else {
                revert();
            }
        }
    }

     
    function deleteUserComment(address _user, uint256 _id) public onlyOwner {
        for(uint i = 0; i < userComments[_user].length; i++) {
            if(userComments[_user][i] == _id){
                delete userComments[_user][i];
            }
        }
    }

     
    function deletePublicComment(uint256 _id) public onlyOwner {
        if(comments[_id].id == _id){
            delete comments[_id];
        }
    }

     
    function deleteComment(address _user, uint256 _id) public onlyOwner {
        deleteUserComment(_user, _id);
        deletePublicComment(_id);
    }

     

    function updateProfile(string _username, string _about, string _profilePic, string _site, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForUpdatingProfile);
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            if (users[msg.sender].id != msg.sender) {
                User memory user = User(msg.sender, '', '', '', '');
                users[msg.sender] = user;
            }
            if (bytes(_username).length > 0) {
                users[msg.sender].username = _username;
            }
            if (bytes(_about).length > 0) {
                users[msg.sender].about = _about;
            }
            if (bytes(_profilePic).length > 0) {
                users[msg.sender].profilePic = _profilePic;
            }
            if (bytes(_site).length > 0) {
                users[msg.sender].site = _site;
            }
        } else {
            revert();
        }
    }


     

    function follow(address _address, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForFollow);
        require(msg.sender != _address);
         
        if (wednesdayCoin.transferFrom(msg.sender, _address, _value)) {
            following[msg.sender].push(_address);
             
            followers[_address].push(msg.sender);
        } else {
            revert();
        }
    }

    function unfollow(address _address) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(msg.sender != _address);
         
        for(uint i = 0; i < following[msg.sender].length; i++) {
            if(following[msg.sender][i] == _address){
                delete following[msg.sender][i];
            }
        }
         
        for(i = 0; i < followers[_address].length; i++) {
            if(followers[_address][i] == msg.sender){
                delete followers[_address][i];
            }
        }
    }

     

    function blockUser(address _address, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForBlockingUser);
        require(msg.sender != _address);
         
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            blockedUsers[msg.sender].push(_address);
        } else {
            revert();
        }
    }

    function unblockUser(address _address) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(msg.sender != _address);
         
        for(uint i = 0; i < blockedUsers[msg.sender].length; i++) {
            if(blockedUsers[msg.sender][i] == _address){
                delete blockedUsers[msg.sender][i];
            }
        }
    }

     

     
    function transferAnyERC20Token(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }

     
    function transferEther(address _dest, uint _amount) public onlyOwner {
        _dest.transfer(_amount);
    }

     
    function nukeMe() public {
        nukePosts();
        nukeComments();
        nukeUser();
    }

    function nukePosts() public {
        for (uint i = 0; i < userPosts[msg.sender].length; i++) {
            uint256 id = userPosts[msg.sender][i];
            delete posts[id];
            delete postIds[id];
        }
        delete userPosts[msg.sender];
    }

    function nukeComments() public {
        for (uint i = 0; i < userComments[msg.sender].length; i++) {
            uint256 id = userComments[msg.sender][i];
            delete comments[id];
        }
        delete userComments[msg.sender];
    }

    function nukeUser() public {
        delete users[msg.sender];
        delete blockedUsers[msg.sender];
        delete followers[msg.sender];
        delete following[msg.sender];
    }
}