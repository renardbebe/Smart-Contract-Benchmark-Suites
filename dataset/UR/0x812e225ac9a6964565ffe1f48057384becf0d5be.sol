 
    function setCallAddress(address _callAddress)
    public
    onlyOwner
    onlyAddProjectsState
    {
        callObj = ICALL(_callAddress);
    }

    function setClearTime(uint256 _clearTime)
    public
    onlyOwner
    onlyAddProjectsState
    {
        clearTime = _clearTime;
    }

    function setVoteTime(uint256 _votingTime)
    public
    onlyOwner
    onlyAddProjectsState
    {
        votingTime = _votingTime;
    }

    function setLimit(uint256 _noOfProjects)
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjects = _noOfProjects;
    }

    function checkVoteState()
    public
    onlyVoteState
    {
        if (voteEndTime <= now) _startRefundState();  
    }

    function checkRefundState()
    public
    {
        if (voteEndTime.add(clearTime) <= now) _startClearState();  
    }

     
     
     


    function addProjects(
        bytes32[10] memory _titles,
        bytes32[10] memory _ipfsData,
        uint8[10] memory _ipfsHashFunction,
        uint8[10] memory _ipfsSize
    )
    public
    onlyOwner
    onlyAddProjectsState
    {
        uint256 loopMax = noOfProjects.sub(noOfProjectsAdded);

        if (loopMax > 10) loopMax = 10;

        for (uint256 i = 0; i < loopMax; i++) {   
            noOfProjectsAdded = noOfProjectsAdded.add(1);
            Ipfs memory ipfs = Ipfs(_ipfsData[i], _ipfsHashFunction[i], _ipfsSize[i]);
            Project memory project;
            project.title = _titles[i];
            project.id = noOfProjectsAdded;

            emit ProjectAdded(_titles[i], _ipfsData[i], _ipfsHashFunction[i], _ipfsSize[i], noOfProjectsAdded, round);

            projects[noOfProjectsAdded] = project;
            ipfses[noOfProjectsAdded] = ipfs;
        }

        if (noOfProjectsAdded == noOfProjects) {
            noOfProjectsAdded = 0;
            _startVoteState(now.add(votingTime));  
        }
    }

    function addProject(
        bytes32 _title,
        bytes32 _ipfsData,
        uint8 _ipfsHashFunction,
        uint8 _ipfsSize
    )
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjectsAdded = noOfProjectsAdded.add(1);
        Ipfs memory ipfs = Ipfs(_ipfsData, _ipfsHashFunction, _ipfsSize);
        Project memory project;
        project.title = _title;
        project.id = noOfProjectsAdded;

        emit ProjectAdded(_title, _ipfsData, _ipfsHashFunction, _ipfsSize, noOfProjectsAdded, round);

        projects[noOfProjectsAdded] = project;
        ipfses[noOfProjectsAdded] = ipfs;

        if (noOfProjectsAdded == noOfProjects) {
            noOfProjectsAdded = 0;
            _startVoteState(now.add(votingTime));  
        }
    }

    function restartAddProjectsState()
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjectsAdded = 0;
    }

     
     
     


     
     
     


     
    function tokensReceived(
        address operator,  
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )   
    public
    onlyCall
    {
        require(userData[0] <= bytes1(uint8(noOfProjects)) && userData[0] > 0x00, "ProjectVoting: Wrong Id");
        _vote(from, amount,  uint8(userData[0]));
    }

     
     
     

     
     
     

      
    function returnFunds(uint256[] memory _positions)
    public
    onlyRefundState
    onlyInRefundTime
    {
        uint256 size;

        for (uint256 pos = 0; pos < _positions.length; pos++) {
            if (_positions[pos] < totalVoters && powerOf[voters[_positions[pos]]] != 0) size = size.add(1);
        }

        address[] memory addresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);

        uint256 counter;

        for (uint256 pos = 0; pos < _positions.length; pos++) {
            if (powerOf[voters[_positions[pos]]] != 0 && _positions[pos] < totalVoters) {
                addresses[counter] = voters[_positions[pos]];
                amounts[counter] = powerOf[addresses[counter]];
                totalToRefund = totalToRefund.sub(1);
                powerOf[addresses[counter]] = 0;
                counter = counter.add(1);
            }
        }
        callObj.multiPartySend(addresses, amounts, "");
        _startAddProjectsState();
    }

    function returnFunds(uint256 _start, uint256 _stop)
    public
    onlyRefundState
    onlyInRefundTime
    {
        if (_stop > totalVoters) _stop = totalVoters;
        uint256 size = _stop.sub(_start);
        address[] memory addresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);
        uint256 arrCurr = 0;
        for (uint256 pos = _start; pos < _stop; pos++) {
            addresses[arrCurr] = voters[pos];
            amounts[arrCurr] = powerOf[addresses[arrCurr]];
            if (amounts[arrCurr] != 0) {
                totalToRefund = totalToRefund.sub(1);
                powerOf[addresses[arrCurr]] = 0;
            }
            arrCurr = arrCurr.add(1);
        }
        callObj.multiPartySend(addresses, amounts, "");  
        _startAddProjectsState();
    }

    function returnFunds()
    public
    onlyRefundState
    onlyInRefundTime
    {
        uint256 amount = powerOf[msg.sender];
        if (amount == 0) return;
        totalToRefund = totalToRefund.sub(1);
        powerOf[msg.sender] = 0;
        callObj.send(msg.sender, amount, "");  
        _startAddProjectsState();
    }

    function executeClear(uint256[] memory _positions) public onlyClearState {
        for (uint256 pos = 0; pos < _positions.length; pos++) {
            address addr = voters[_positions[pos]];
            if (powerOf[addr] != 0) {
                totalToRefund = totalToRefund.sub(1);
                powerOf[addr] = 0;
            }
        }
        _startAddProjectsState();
    }

     

    function _startAddProjectsState() internal {
        if (totalToRefund == 0) {
            voteEndTime = 0;
            uint256 balance = callObj.balanceOf(address(this));
            PVoteState oldState = state;  

            state = PVoteState.ADD_PROJECTS;  
            emit PVoteStateChanged(oldState, PVoteState.ADD_PROJECTS, round);
            round = round.add(1);
            if (balance != 0) callObj.send(owner(), balance, "");  
        }
    }

    function _startVoteState(uint256 _endTime) internal {
         
        require(_endTime > now, "ProjectVoting: timestamp must be a point in the future");
        voteEndTime = _endTime;
        state = PVoteState.VOTE;
        emit PVoteStateChanged(PVoteState.ADD_PROJECTS, PVoteState.VOTE, round);
        totalVoters = 0;  
    }

    function _startRefundState() internal {
        state = PVoteState.REFUND;
        emit PVoteStateChanged(PVoteState.VOTE, PVoteState.REFUND, round);
        winnerId = winningId;
        emit Winner(winnerId, round);
        winningId = 0;
        totalToRefund = totalVoters;
         
    }

    function _startClearState() internal {
        state = PVoteState.CLEAR;
        emit PVoteStateChanged(PVoteState.REFUND, PVoteState.CLEAR, round);
    }

     
    function _vote(address _sender, uint256 _power, uint256 _id)
    internal
    onlyVoteState
    onlyInVoteTime
    {
        require(_power != 0, "ProjectVoting: Cannot vote with 0 value");

        if (powerOf[_sender] == 0) {
            powerOf[_sender] = _power;
            voters[totalVoters] = _sender;
            totalVoters = totalVoters.add(1);
            votedFor[_sender] = _id;
        } else {
            require(votedFor[_sender] == _id, "ProjectVoting: Cannot vote for different projects");
            powerOf[_sender] = powerOf[_sender].add(_power);
        }
        projects[_id].value = projects[_id].value.add(_power);

        emit Vote(_sender, _power, _id, round);

        if (projects[_id].value > projects[winningId].value) winningId = _id;
    }

     
     
     
}
