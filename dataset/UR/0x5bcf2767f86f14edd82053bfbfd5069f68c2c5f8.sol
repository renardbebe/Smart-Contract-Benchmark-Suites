 
    function setCeiling(uint _newCeiling) external onlyController {
        emit CeilingUpdated(ceiling, _newCeiling);

        ceiling = _newCeiling;
        max = total.mul(ceiling).div(decimals);
        safeMax = uint(77).mul(max).div(100);
    }

     
    function createDApp(bytes32 _id, uint _amount, bytes32 _metadata) external {
        _createDApp(
            msg.sender,
            _id,
            _amount,
            _metadata);
    }

     
    function upvote(bytes32 _id, uint _amount) external {
        _upvote(msg.sender, _id, _amount);
    }

     
    function downvote(bytes32 _id, uint _amount) external {
        _downvote(msg.sender, _id, _amount);
    }

     
    function withdrawMax(bytes32 _id) external view returns(uint) {
        Data storage d = _getDAppById(_id);
        return d.available;
    }

     
    function withdraw(bytes32 _id, uint _amount) external {

        Data storage d = _getDAppById(_id);

        uint256 tokensQuantity = _amount.div(1 ether);

        require(msg.sender == d.developer, "Only the developer can withdraw SNT staked on this data");
        require(tokensQuantity <= d.available, "You can only withdraw a percentage of the SNT staked, less what you have already received");

        uint precision;
        uint result;

        d.balance = d.balance.sub(tokensQuantity);
        d.rate = decimals.sub(d.balance.mul(decimals).div(max));
        d.available = d.balance.mul(d.rate);

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;
        if (d.votesCast > d.votesMinted) {
            d.votesCast = d.votesMinted;
        }

        uint temp1 = d.votesCast.mul(d.rate).mul(d.available);
        uint temp2 = d.votesMinted.mul(decimals).mul(decimals);
        uint effect = temp1.div(temp2);

        d.effectiveBalance = d.balance.sub(effect);

        require(SNT.transfer(d.developer, _amount), "Transfer failed");

        emit Withdraw(_id, d.effectiveBalance);
    }

     
    function setMetadata(bytes32 _id, bytes32 _metadata) external {
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.developer == msg.sender, "Only the developer can update the metadata");
        d.metadata = _metadata;
        emit MetadataUpdated(_id);
    }

     
    function getDAppsCount() external view returns(uint) {
        return dapps.length;
    }

     
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes calldata _data
    )
        external
    {
        require(_token == address(SNT), "Wrong token");
        require(_token == address(msg.sender), "Wrong account");
        require(_data.length <= 196, "Incorrect data");

        bytes4 sig;
        bytes32 id;
        uint256 amount;
        bytes32 metadata;

        (sig, id, amount, metadata) = abiDecodeRegister(_data);
        require(_amount == amount, "Wrong amount");

        if (sig == bytes4(0x7e38d973)) {
            _createDApp(
                _from,
                id,
                amount,
                metadata);
        } else if (sig == bytes4(0xac769090)) {
            _downvote(_from, id, amount);
        } else if (sig == bytes4(0x2b3df690)) {
            _upvote(_from, id, amount);
        } else {
            revert("Wrong method selector");
        }
    }

     
    function upvoteEffect(bytes32 _id, uint _amount) external view returns(uint effect) {
        Data memory d = _getDAppById(_id);
        require(d.balance.add(_amount) <= safeMax, "You cannot upvote by this much, try with a lower amount");

         
        if (d.votesCast == 0) {
            return _amount;
        }

        uint precision;
        uint result;

        uint mBalance = d.balance.add(_amount);
        uint mRate = decimals.sub(mBalance.mul(decimals).div(max));
        uint mAvailable = mBalance.mul(mRate);

        (result, precision) = BancorFormula.power(
            mAvailable,
            decimals,
            uint32(decimals),
            uint32(mRate));

        uint mVMinted = result >> precision;

        uint temp1 = d.votesCast.mul(mRate).mul(mAvailable);
        uint temp2 = mVMinted.mul(decimals).mul(decimals);
        uint mEffect = temp1.div(temp2);

        uint mEBalance = mBalance.sub(mEffect);

        return (mEBalance.sub(d.effectiveBalance));
    }

      
    function downvoteCost(bytes32 _id) external view returns(uint b, uint vR, uint c) {
        Data memory d = _getDAppById(_id);
        return _downvoteCost(d);
    }

    function _createDApp(
        address _from,
        bytes32 _id,
        uint _amount,
        bytes32 _metadata
        )
      internal
      {
        require(!existingIDs[_id], "You must submit a unique ID");

        uint256 tokensQuantity = _amount.div(1 ether);

        require(tokensQuantity > 0, "You must spend some SNT to submit a ranking in order to avoid spam");
        require (tokensQuantity <= safeMax, "You cannot stake more SNT than the ceiling dictates");

        uint dappIdx = dapps.length;

        dapps.length++;

        Data storage d = dapps[dappIdx];
        d.developer = _from;
        d.id = _id;
        d.metadata = _metadata;

        uint precision;
        uint result;

        d.balance = tokensQuantity;
        d.rate = decimals.sub((d.balance).mul(decimals).div(max));
        d.available = d.balance.mul(d.rate);

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;
        d.votesCast = 0;
        d.effectiveBalance = tokensQuantity;

        id2index[_id] = dappIdx;
        existingIDs[_id] = true;

        require(SNT.transferFrom(_from, address(this), _amount), "Transfer failed");

        emit DAppCreated(_id, d.effectiveBalance);
    }

    function _upvote(address _from, bytes32 _id, uint _amount) internal {
        uint256 tokensQuantity = _amount.div(1 ether);
        require(tokensQuantity > 0, "You must send some SNT in order to upvote");

        Data storage d = _getDAppById(_id);

        require(d.balance.add(tokensQuantity) <= safeMax, "You cannot upvote by this much, try with a lower amount");

        uint precision;
        uint result;

        d.balance = d.balance.add(tokensQuantity);
        d.rate = decimals.sub((d.balance).mul(decimals).div(max));
        d.available = d.balance.mul(d.rate);

        (result, precision) = BancorFormula.power(
            d.available,
            decimals,
            uint32(decimals),
            uint32(d.rate));

        d.votesMinted = result >> precision;

        uint temp1 = d.votesCast.mul(d.rate).mul(d.available);
        uint temp2 = d.votesMinted.mul(decimals).mul(decimals);
        uint effect = temp1.div(temp2);

        d.effectiveBalance = d.balance.sub(effect);

        require(SNT.transferFrom(_from, address(this), _amount), "Transfer failed");

        emit Upvote(_id, d.effectiveBalance);
    }

    function _downvote(address _from, bytes32 _id, uint _amount) internal {
        uint256 tokensQuantity = _amount.div(1 ether);
        Data storage d = _getDAppById(_id);
        (uint b, uint vR, uint c) = _downvoteCost(d);

        require(tokensQuantity == c, "Incorrect amount: valid iff effect on ranking is 1%");

        d.available = d.available.sub(tokensQuantity);
        d.votesCast = d.votesCast.add(vR);
        d.effectiveBalance = d.effectiveBalance.sub(b);

        require(SNT.transferFrom(_from, d.developer, _amount), "Transfer failed");

        emit Downvote(_id, d.effectiveBalance);
    }

    function _downvoteCost(Data memory d) internal view returns(uint b, uint vR, uint c) {
        uint balanceDownBy = (d.effectiveBalance.div(100));
        uint votesRequired = (balanceDownBy.mul(d.votesMinted).mul(d.rate)).div(d.available);
        uint votesAvailable = d.votesMinted.sub(d.votesCast).sub(votesRequired);
        uint temp = (d.available.div(votesAvailable)).mul(votesRequired);
        uint cost = temp.div(decimals);
        return (balanceDownBy, votesRequired, cost);
    }

     
    function _getDAppById(bytes32 _id) internal view returns(Data storage d) {
        uint dappIdx = id2index[_id];
        d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
    }

      
    function abiDecodeRegister(
        bytes memory _data
    )
        private
        pure
        returns(
            bytes4 sig,
            bytes32 id,
            uint256 amount,
            bytes32 metadata
        )
    {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            id := mload(add(_data, 36))
            amount := mload(add(_data, 68))
            metadata := mload(add(_data, 100))
        }
    }
}
