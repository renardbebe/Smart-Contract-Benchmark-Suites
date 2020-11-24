 
    modifier onlyOwner() {
        require(msg.sender == _owner, "only Owner");
        _;
    }

      
    modifier onlyExternalWallet() {
        require(msg.sender == externalWallet, "only External Wallet can call this function");
        _;
    }

     
    modifier isActivated() {
        require(activated_ == true, "ouch, contract is not ready yet !");
        _;
    }


     
    modifier isHuman() {
        require(msg.sender == tx.origin, "nope, you're not an Human buddy !!");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 50000000000000000, "Minimum contribution amount is 0.05 ETH");
        _;
    }
 
 

    function changeKeyPrice(uint256 _amt)
        onlyOwner()
        public
    {
        keyPrice = _amt;
    }

    function changeExternalWallet(address _newAddress)
    onlyOwner()
    public
    returns (bool)
    {
        require(_newAddress != address(0x0));

        externalWallet = _newAddress;
        return true;

    }

    function ()
        isHuman()
        isWithinLimits(msg.value)
        isActivated()
        public
        payable
    {
         
        DataStructs.EventReturns memory _eventData_ =  _eventData_;

         
         address _playerAddr = msg.sender;

         
        purchaseCore(_playerAddr, 0x0, _eventData_);
    }

      
    function owner() public view returns (address) {
        return _owner;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

      
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function stopLuckyDraw()
        onlyOwner()
        public
    {
        require(luckyDrawEnabled = true, "Luckydraw is already stopped");
        luckyDrawEnabled = false;
    }

    function startLuckyDraw()
        onlyOwner()
        public
    {
        require(luckyDrawEnabled = false, "Lucky draw is already running");
        luckyDrawEnabled = true;
    }


    function reinvestDividendEarnings(uint256 _keys)
        isHuman()
        isActivated()
        private
    {

        address _playerAddr = msg.sender;

         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

        address _affAddr = firstReferrer[msg.sender];
        uint256 _eth = _keys.mul(keyPrice).div(1000000000000000000);
        uint256 _rID = rID_;

        if (plyrRnds_[_playerAddr][_rID].keys == 0) {
            _eventData_ = managePlayer(_playerAddr, _eventData_);
            round_[_rID].playerCounter = round_[_rID].playerCounter + 1;

        }

         
        if (_keys >= 1000000000000000000)
        {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _playerAddr)
                round_[_rID].plyr = _playerAddr;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }

         
        plyrRnds_[_playerAddr][_rID].keys = (_keys.mul(1).div(100)).add(plyrRnds_[_playerAddr][_rID].keys);
        plyrRnds_[_playerAddr][_rID].eth = plyrRnds_[_playerAddr][_rID].eth.add(_eth);
        plyr_[_playerAddr].eth = plyr_[_playerAddr].eth.add(_eth);

         
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = round_[_rID].eth.add(_eth);
        investors[_playerAddr][investorDistRound] = investors[_playerAddr][investorDistRound].add(_eth);
        addInvestor(_playerAddr);
        luckyDraw.add(_playerAddr);

         
        if (now.sub(lastLuckyDrawTime) >= luckyDrawDuration  && luckyDrawEnabled == true){
             
            address luckyDrawWinner = luckyDraw.draw();
            plyr_[luckyDrawWinner].gen = plyr_[luckyDrawWinner].gen.add(luckyDrawVault_);
            lastLuckyDrawAmt = luckyDrawVault_;
            luckyDrawVault_ = 0;
            lastLuckyDrawTime = now;
            emit luckyDrawDeclared(luckyDrawWinner, lastLuckyDrawAmt, now);
        }


        _eventData_ = distributeInternal(_rID, _playerAddr, _affAddr, _keys, _eventData_);

    }

    function reinvestReferralEarnings(uint256 _keys)
        isHuman()
        isActivated()
        private
    {

        address _playerAddr = msg.sender;

         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

        address _affAddr = firstReferrer[msg.sender];
        uint256 _eth = _keys.mul(keyPrice).div(1000000000000000000);
        uint256 _rID = rID_;

        if (plyrRnds_[_playerAddr][_rID].keys == 0) {
            _eventData_ = managePlayer(_playerAddr, _eventData_);
            round_[_rID].playerCounter = round_[_rID].playerCounter + 1;

        }

         
        if (_keys >= 1000000000000000000)
        {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _playerAddr)
                round_[_rID].plyr = _playerAddr;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }
         
        plyrRnds_[_playerAddr][_rID].keys = (_keys.mul(1).div(100)).add(plyrRnds_[_playerAddr][_rID].keys);
        plyrRnds_[_playerAddr][_rID].eth = plyrRnds_[_playerAddr][_rID].eth.add(_eth);
        plyr_[_playerAddr].eth = plyr_[_playerAddr].eth.add(_eth);

         
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = round_[_rID].eth.add(_eth);

        investors[_playerAddr][investorDistRound] = investors[_playerAddr][investorDistRound].add(_eth);
        addInvestor(_playerAddr);
        luckyDraw.add(_playerAddr);

         
        if (now.sub(lastLuckyDrawTime) >= luckyDrawDuration && luckyDrawEnabled == true){
             
            address luckyDrawWinner = luckyDraw.draw();
            plyr_[luckyDrawWinner].gen = plyr_[luckyDrawWinner].gen.add(luckyDrawVault_);
            lastLuckyDrawAmt = luckyDrawVault_;
            luckyDrawVault_ = 0;
            lastLuckyDrawTime = now;
            emit luckyDrawDeclared(luckyDrawWinner, lastLuckyDrawAmt, now);
        }


        _eventData_ = distributeInternal(_rID, _playerAddr, _affAddr, _keys, _eventData_);

    }

    function reinvestAllEarnings()
        isHuman()
        isActivated()
        public
    {

        address _playerAddr = msg.sender;
        uint256 _rID = rID_;
        uint256 eth = 0;
        uint256 _now = now;

         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {

            updateGenVault(_playerAddr, plyr_[_playerAddr].lrnd);

            uint256 _keys = referralBalance_[_playerAddr].add(plyr_[_playerAddr].gen);
            require(_keys > 0, "Sorry, you don't have sufficient earning to reinvest");

             
            playerEarned_[_playerAddr][_rID] = playerEarned_[_playerAddr][_rID].add(plyr_[_playerAddr].gen);
            referralBalance_[_playerAddr] = 0;
            plyr_[_playerAddr].gen = 0;

            address _affAddr = firstReferrer[msg.sender];
            uint256 _eth = _keys.mul(keyPrice).div(1000000000000000000);
            eth = _eth;

            if (plyrRnds_[_playerAddr][_rID].keys == 0) {
            _eventData_ = managePlayer(_playerAddr, _eventData_);
            round_[_rID].playerCounter = round_[_rID].playerCounter + 1;

        }


             
            if (_keys >= 1000000000000000000)
            {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _playerAddr)
                round_[_rID].plyr = _playerAddr;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
            }
             
            plyrRnds_[_playerAddr][_rID].keys = (_keys.mul(1).div(100)).add(plyrRnds_[_playerAddr][_rID].keys);
            plyrRnds_[_playerAddr][_rID].eth = plyrRnds_[_playerAddr][_rID].eth.add(_eth);
            plyr_[_playerAddr].eth = plyr_[_playerAddr].eth.add(_eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = round_[_rID].eth.add(_eth);


             
             _eventData_ = distributeInternal(_rID, _playerAddr, _affAddr, _keys, _eventData_);
        }
         
        else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
             

             
            emit Events.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_playerAddr].name,
                _eventData_.compressedData,
                
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );
        }

        investors[_playerAddr][investorDistRound] = investors[_playerAddr][investorDistRound].add(eth);
        addInvestor(_playerAddr);
        luckyDraw.add(_playerAddr);

         
        if (now.sub(lastLuckyDrawTime) >= luckyDrawDuration  && luckyDrawEnabled == true){
             
            address luckyDrawWinner = luckyDraw.draw();
            plyr_[luckyDrawWinner].gen = plyr_[luckyDrawWinner].gen.add(luckyDrawVault_);
            lastLuckyDrawAmt = luckyDrawVault_;
            luckyDrawVault_ = 0;
            lastLuckyDrawTime = now;
            emit luckyDrawDeclared(luckyDrawWinner, lastLuckyDrawAmt, now);
        }

    }

    function withdrawDividendEarnings()
        isActivated()
        isHuman()
        public
    {
        uint256 _now = now;
        uint256 _rID = rID_;

        address _playerAddress = msg.sender;

         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

         
        if (_now > round_[_rID].strt  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            updateGenVault(_playerAddress, plyr_[_playerAddress].lrnd);

            uint256 _earnings = plyr_[_playerAddress].gen + plyr_[_playerAddress].win;

            if(_earnings > 0)
            {
                uint256 _withdrawAmount = (_earnings.div(2)).mul(keyPrice).div(1000000000000000000);
                uint256 _reinvestAmount = _earnings.div(2);
                _earnings = 0;

                require(address(this).balance >= _withdrawAmount, "Contract doesn't have sufficient amount to give you");

                playerEarned_[_playerAddress][_rID] = playerEarned_[_playerAddress][_rID].add(plyr_[_playerAddress].gen);
                plyr_[_playerAddress].gen = 0;
                plyr_[_playerAddress].win = 0;
                totalSupply_ = totalSupply_.sub(_reinvestAmount);

                address(msg.sender).transfer(_withdrawAmount);
                reinvestDividendEarnings(_reinvestAmount);
            }

             
            emit Events.onWithdrawFunds
            (
                msg.sender,
                _withdrawAmount,
                now
            );

        }

         
        else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);

             
            emit Events.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_playerAddress].name,
                _eventData_.compressedData,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );
        }


    }

    function withdrawReferralEarnings ()
        isHuman()
        isActivated()
        public
     {

        address _playerAddress = msg.sender;
         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

        require(referralBalance_[_playerAddress] > 0, "Sorry, you can't withdraw 0 referral earning");

        uint256 _now = now;
        uint256 _rID = rID_;

         
        if (_now > round_[_rID].strt  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
            uint256 _earnings = referralBalance_[_playerAddress];

            if(_earnings > 0)
            {
                uint256 _withdrawAmount = (_earnings.div(2)).mul(keyPrice).div(1000000000000000000);
                uint256 _reinvestAmount = _earnings.div(2);
                _earnings = 0;

                require(address(this).balance >= _withdrawAmount, "Contract doesn't have sufficient amount to give you");

                referralBalance_[_playerAddress] = 0;

                totalSupply_ = totalSupply_.sub(_reinvestAmount);

                address(msg.sender).transfer(_withdrawAmount);
                reinvestReferralEarnings(_reinvestAmount);

                 
                emit Events.onWithdrawFunds
                (
                    msg.sender,
                    _withdrawAmount,
                    now
                );
            }
        }

         
        else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);

             
            emit Events.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_playerAddress].name,
                _eventData_.compressedData,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );
        }

     }

     function distributeTopInvestors()
        onlyOwner()
        public
    {
        if (now.sub(lastInvestorDistTime) >= topleaderboardDuration){

            uint256 totAmt = topInvestorsVault;
            topInvestorsVault = 0;
            investorDistRound = investorDistRound.add(1);

            address first = topInvestors[0].addr;
            address second  = topInvestors[1].addr;
            address third  = topInvestors[2].addr;

            plyr_[first].gen = plyr_[first].gen.add(totAmt.mul(50).div(100));
            topInvestors[0].addr = address(0x0);
            topInvestors[0].amt = 0;

            plyr_[second].gen = plyr_[second].gen.add(totAmt.mul(30).div(100));
            topInvestors[1].addr = address(0x0);
            topInvestors[1].amt = 0;

            plyr_[third].gen = plyr_[third].gen.add(totAmt.mul(20).div(100));
            topInvestors[2].addr = address(0x0);
            topInvestors[2].amt = 0;

            lastTopInvestors[0] = first;
            lastTopInvestors[1] = second;
            lastTopInvestors[2] = third;

            emit topInvestorsDistribute(first, second, third);
        }
        else{
            revert("There is still time or a round is running");
        }
    }

    function distributeTopPromoters()
        onlyOwner()
        public
    {
        if (now.sub(lastPromoterDistTime) >= topleaderboardDuration){

            uint256 totAmt = topPromotersVault;
            topPromotersVault = 0;
            investorDistRound = investorDistRound.add(1);

            address first = topPromoters[0].addr;
            address second  = topPromoters[1].addr;
            address third  = topPromoters[2].addr;

            plyr_[first].gen = plyr_[first].gen.add(totAmt.mul(50).div(100));
            topPromoters[0].addr = address(0x0);
            topPromoters[0].amt = 0;

            plyr_[second].gen = plyr_[second].gen.add(totAmt.mul(30).div(100));
            topPromoters[1].addr = address(0x0);
            topPromoters[1].amt = 0;

            plyr_[third].gen = plyr_[third].gen.add(totAmt.mul(20).div(100));
            topPromoters[2].addr = address(0x0);
            topPromoters[2].amt = 0;

            lastTopPromoters[0] = first;
            lastTopPromoters[1] = second;
            lastTopPromoters[2] = third;

            emit topPromotersDistribute(first, second, third);

        }
        else{
            revert("There is still time.");
        }
    }

    function addPromoter(address _add)
        isActivated()
        private
        returns (bool)
    {
        if (_add == address(0x0)){
            return false;
        }

        uint256 _amt = promoters[_add][promoterDistRound];
         
        if (topPromoters[2].amt >= _amt){
            return false;
        }

        address firstAddr = topPromoters[0].addr;
        uint256 firstAmt = topPromoters[0].amt;
        address secondAddr = topPromoters[1].addr;
        uint256 secondAmt = topPromoters[1].amt;


         
        if (_amt > topPromoters[0].amt){

            if (topPromoters[0].addr == _add){
                topPromoters[0].amt = _amt;
                return true;
            }
            else{
                firstAddr = topPromoters[0].addr;
                firstAmt = topPromoters[0].amt;
                secondAddr = topPromoters[1].addr;
                secondAmt = topPromoters[1].amt;

                topPromoters[0].addr = _add;
                topPromoters[0].amt = _amt;
                topPromoters[1].addr = firstAddr;
                topPromoters[1].amt = firstAmt;
                topPromoters[2].addr = secondAddr;
                topPromoters[2].amt = secondAmt;
                return true;
            }
        }
         
        else if (_amt >= topPromoters[1].amt){

            if (topPromoters[0].addr == _add){
                topPromoters[0].amt = _amt;
                return true;
            }
            else if (topPromoters[1].addr == _add){
                topPromoters[1].amt = _amt;
                return true;
            }
            else{
                secondAddr = topPromoters[1].addr;
                secondAmt = topPromoters[1].amt;

                topPromoters[1].addr = _add;
                topPromoters[1].amt = _amt;
                topPromoters[2].addr = secondAddr;
                topPromoters[2].amt = secondAmt;
                return true;
            }

        }
         
        else if (_amt >= topPromoters[2].amt){

            if (topPromoters[0].addr == _add){
                topPromoters[0].amt = _amt;
                return true;
            }
            else if (topPromoters[1].addr == _add){
                topPromoters[1].amt = _amt;
                return true;
            }
            else if (topPromoters[2].addr == _add){
                topPromoters[2].amt = _amt;
                return true;
            }
            else{
                topPromoters[2].addr = _add;
                topPromoters[2].amt = _amt;
                return true;
            }

        }

    }

    function addInvestor(address _add)
        isActivated()
        private
        returns (bool)
    {
        if (_add == address(0x0)){
            return false;
        }

        uint256 _amt = investors[_add][investorDistRound];
         
        if (topInvestors[2].amt >= _amt){
            return false;
        }

        address firstAddr = topInvestors[0].addr;
        uint256 firstAmt = topInvestors[0].amt;
        address secondAddr = topInvestors[1].addr;
        uint256 secondAmt = topInvestors[1].amt;

         
        if (_amt > topInvestors[0].amt){

            if (topInvestors[0].addr == _add){
                topInvestors[0].amt = _amt;
                return true;
            }
            else{
                firstAddr = topInvestors[0].addr;
                firstAmt = topInvestors[0].amt;
                secondAddr = topInvestors[1].addr;
                secondAmt = topInvestors[1].amt;

                topInvestors[0].addr = _add;
                topInvestors[0].amt = _amt;
                topInvestors[1].addr = firstAddr;
                topInvestors[1].amt = firstAmt;
                topInvestors[2].addr = secondAddr;
                topInvestors[2].amt = secondAmt;
                return true;
            }
        }
         
        else if (_amt >= topInvestors[1].amt){

            if (topInvestors[0].addr == _add){
                topInvestors[0].amt = _amt;
                return true;
            }
            else if (topInvestors[1].addr == _add){
                topInvestors[1].amt = _amt;
                return true;
            }
            else{
                secondAddr = topInvestors[1].addr;
                secondAmt = topInvestors[1].amt;

                topInvestors[1].addr = _add;
                topInvestors[1].amt = _amt;
                topInvestors[2].addr = secondAddr;
                topInvestors[2].amt = secondAmt;
                return true;
            }

        }
         
        else if (_amt >= topInvestors[2].amt){

            if (topInvestors[0].addr == _add){
                topInvestors[0].amt = _amt;
                return true;
            }
            else if (topInvestors[1].addr == _add){
                topInvestors[1].amt = _amt;
                return true;
            }
            else if (topInvestors[2].addr == _add){
                topInvestors[2].amt = _amt;
                return true;
            }
            else{
                topInvestors[2].addr = _add;
                topInvestors[2].amt = _amt;
                return true;
            }

        }

    }

    function purchaseViaAddr(address _affAddress)
        isHuman()
        isActivated()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

         
        address _playerAddr = msg.sender;
        address _affAddr = _affAddress;

         
        purchaseCore(_playerAddr, _affAddr, _eventData_);
    }

    function purchaseViaName(bytes32 _affName)
        isHuman()
        isActivated()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        DataStructs.EventReturns memory _eventData_ = _eventData_;

         
        address _playerAddr = msg.sender;
        address _affAddr = pAddrxName[_affName];

         
        purchaseCore(_playerAddr, _affAddr, _eventData_);
    }

    function purchaseCore(address _playerAddr, address _affAddr, DataStructs.EventReturns memory _eventData_)
        private
    {

        uint256 _rID = rID_;
        uint256 _now = now;

         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             

             coreLogic(_rID, _playerAddr, msg.value, _affAddr, _eventData_);


         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
			    round_[_rID].ended = true;
                  _eventData_ = endRound(_eventData_);

                 
                 _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);

                  
                emit onRoundEnd
                (
                    _eventData_,
                    msg.sender,
                    _eventData_.compressedIDs,
                    _eventData_.newPot,
                    msg.value,
                    _eventData_.genAmount
                );

            }

             
            address(_playerAddr).transfer(msg.value);
        }
    }

     
    function coreLogic(uint256 _rID, address _playerAddr, uint256 _eth, address _affAddr, DataStructs.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_playerAddr][_rID].keys == 0) {
            _eventData_ = managePlayer(_playerAddr, _eventData_);
            round_[_rID].playerCounter = round_[_rID].playerCounter + 1;
        }


        uint256 amountToExternalWallet = _eth.div(2);
        address(externalWallet).transfer(amountToExternalWallet);

         
        uint256 _keys = keysRec(_eth);

         
        if (_keys >= 1000000000000000000)
        {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _playerAddr)
                round_[_rID].plyr = _playerAddr;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }

         
         plyrRnds_[_playerAddr][_rID].keys = (_keys.mul(1).div(100)).add(plyrRnds_[_playerAddr][_rID].keys);
         plyrRnds_[_playerAddr][_rID].eth = _eth.add(plyrRnds_[_playerAddr][_rID].eth);
         plyr_[_playerAddr].eth = plyr_[_playerAddr].eth.add(_eth);

         
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _eth.add(round_[_rID].eth);

         

        _eventData_ = distributeInternal(_rID, _playerAddr, _affAddr, _keys, _eventData_);

        investors[_playerAddr][investorDistRound] = investors[_playerAddr][investorDistRound].add(_eth);
        addInvestor(_playerAddr);
        luckyDraw.add(_playerAddr);

         
        if (now.sub(lastLuckyDrawTime) >= luckyDrawDuration  && luckyDrawEnabled == true){

             
            address luckyDrawWinner = luckyDraw.draw();
            plyr_[luckyDrawWinner].gen = plyr_[luckyDrawWinner].gen.add(luckyDrawVault_);
            lastLuckyDrawAmt = luckyDrawVault_;
            luckyDrawVault_ = 0;
            lastLuckyDrawTime = now;
            emit luckyDrawDeclared(luckyDrawWinner, lastLuckyDrawAmt, now);
        }

    }


     
    function distributeInternal(uint256 _rID, address _playerAddr, address _affAddr, uint256 _keys, DataStructs.EventReturns memory _eventData_)
        private
        returns(DataStructs.EventReturns)
    {
         
        uint256 _keyHolderShare = (_keys.mul(keyHolderFees_)) .div(100);

         
        uint256 _adminShare = (_keys.mul(3)).div(100);
        adminKeyVault_ = adminKeyVault_.add(_adminShare);

         
        uint256 _affShare = (_keys.mul(12)).div(100);

         
        uint256 _treasureAmount = _keys.mul(treasureAmount_).div(100);

         
        topPromotersVault = topPromotersVault.add(_keys.div(100));
        topInvestorsVault = topInvestorsVault.add(_keys.div(100));

         
        uint256 _investorAmount = _keys.mul(1).div(100);
        plyr_[_playerAddr].keys = plyr_[_playerAddr].keys.add(_investorAmount);

        totalSupply_ = totalSupply_.add(_keys);

         
        luckyDrawVault_ = luckyDrawVault_.add(_keys.div(100));

         
         calculateReferralBonus(_affShare,_affAddr,_playerAddr);


        if (round_[_rID].playerCounter == 1)
        {
            round_[_rID].treasure = _keyHolderShare.add(round_[_rID].treasure);
            tokenInvestorsSupply_ = tokenInvestorsSupply_.add(_investorAmount);
        }
        else
        {
             
            updateMasks(_rID, _playerAddr, _keyHolderShare, _investorAmount);
             
            tokenInvestorsSupply_ = tokenInvestorsSupply_.add(_investorAmount);
        }

         
        round_[_rID].treasure = _treasureAmount.add(round_[_rID].treasure);

         
        _eventData_.genAmount = _keyHolderShare.add(_eventData_.genAmount);
        _eventData_.potAmount = _treasureAmount;

        return(_eventData_);
    }

     
    function managePlayer(address _pAddress, DataStructs.EventReturns memory _eventData_)
        private
        returns (DataStructs.EventReturns)
    {
         
         
        if (plyr_[_pAddress].lrnd != 0)
        {
            updateGenVault(_pAddress, plyr_[_pAddress].lrnd);

             

            plyr_[_pAddress].gen = plyr_[_pAddress].gen.add(plyr_[_pAddress].keys);

            plyr_[_pAddress].keys = 0;
        }

        plyr_[_pAddress].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

      
    function endRound(DataStructs.EventReturns memory _eventData_)
        private
        returns (DataStructs.EventReturns)
    {
         
        uint256 _rID = rID_;

         
        address _winPAddress = round_[_rID].plyr;

         
        uint256 _treasure = round_[_rID].treasure;

         
         
        uint256 _winnerAmount = (_treasure.mul(40)) / 100;
        uint256 _adminAmount = (_treasure.mul(19)) / 100;
        uint256 _toCurrentHolders = (_treasure.mul(40)) / 100;
        uint256 _toNextRound = _treasure.div(100);

         
        uint256 _ppt = (_toCurrentHolders.mul(1000000000000000000)) / (tokenInvestorsSupply_);


         
        plyr_[_winPAddress].win = _winnerAmount.add(plyr_[_winPAddress].win);

         
        adminKeyVault_ = adminKeyVault_.add(_adminAmount);

         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.winnerAddr = plyr_[_winPAddress].addr;
        _eventData_.winnerName = plyr_[_winPAddress].name;
        _eventData_.amountWon = _winnerAmount;
        _eventData_.genAmount = _toCurrentHolders;
        _eventData_.newPot = _toNextRound;

        activated_ = false;

        return(_eventData_);
    }

     
    function startNextRound()
        public
        onlyOwner()
    {

         
        uint256 _rID = rID_;

        uint256 _now = now;

          
        DataStructs.EventReturns memory _eventData_ = _eventData_;

         
        if (_now > round_[_rID].end && round_[_rID].ended == false)
        {
              
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
        }


        require(activated_ == false, "round is already runnning.");


        uint256 _treasure = round_[_rID].treasure;
        uint256 _toNextRound = _treasure.div(100);

        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].treasure = _toNextRound;


        activated_ = true;

        emit nextRoundStarted(rID_, round_[_rID].strt, round_[_rID].end);
    }

      
    function getLastLuckyDrawWinner()
        public
        view
        returns(address winner)
    {
        return luckyDraw.getWinner();
    }

     
    function updateLuckDrawContract(address _contractAddress)
        public
        onlyOwner()
    {
        luckyDraw = LuckyDraw(_contractAddress);
    }


     
    function updateGenVault(address _pAddress, uint256 _rIDlast)
        private
    {

        uint256 _earnings;
        uint256 _extraEarnings;
        (_earnings, _extraEarnings) = calcUnMaskedEarnings(_pAddress, _rIDlast);

        if (_earnings > 0)
        {
             
            plyr_[_pAddress].gen = _earnings.add(plyr_[_pAddress].gen);
             
            plyrRnds_[_pAddress][_rIDlast].mask = _earnings.add(plyrRnds_[_pAddress][_rIDlast].mask);

             
            adminKeyVault_ = adminKeyVault_.add(_extraEarnings);
            playerExtraEarnings_[_pAddress][_rIDlast] = playerExtraEarnings_[_pAddress][_rIDlast].add(_extraEarnings);

        }
    }

     
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
         
        uint256 _now = now;

         
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

    function registerName(string _nameString)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _plyrAddress = msg.sender;

        require(pAddrxName[_name] == address(0x0), "Name already registered");

        _owner.transfer(msg.value);

        pAddrxName[_name] = _plyrAddress;
        plyr_[_plyrAddress].name = _name;

         
        emit Events.newName(_plyrAddress, _name, msg.value, now);
    }

    function getPlayerName(address _add)
        public
        view
        returns(bytes32)
    {
        return plyr_[_add].name;
    }


     
    function updateMasks(uint256 _rID, address _playerAddr, uint256 _gen, uint256 _investorAmount)
        private
         
    {
         

             
            uint256 _ppt = (_gen.mul(1000000000000000000)) / (tokenInvestorsSupply_);
            round_[_rID].mask = _ppt.add(round_[_rID].mask);

             
             

            plyrRnds_[_playerAddr][_rID].mask = ((round_[_rID].mask.mul(_investorAmount)) / (1000000000000000000)).add(plyrRnds_[_playerAddr][_rID].mask);

     }


    function transferFundsToSmartContract()
    public
    onlyExternalWallet()
    payable {

    }

    function overtimeWithdraw()
    public
    onlyOwner()
    returns (bool){

        uint256 _now = now;
        uint256 _rID = rID_;

         if (_now > round_[_rID].end && round_[_rID].ended == true)
            {
                if ((_now.sub(round_[_rID].end)) >= 30 days )
                {
                    address(externalWallet).transfer(address(this).balance);
                    return true;
                }
            }
        return false;

    }

    function withdrawTokensByAdmin()
    public
    onlyOwner() {
        uint256 withdrawEthAmount  = adminKeyVault_.mul(keyPrice).div(1000000000000000000);

         
        require(address(this).balance >= withdrawEthAmount,"Not sufficient balance in smart contract");

         
        totalSupply_ = totalSupply_.sub(adminKeyVault_);

        adminKeyVault_ = 0;

         
        address(_owner).transfer(withdrawEthAmount);
    }

    function keysRec(uint256 _newEth)
        internal
        view
        returns (uint256)
    {
        return(_newEth.div(keyPrice).mul(1000000000000000000));  
    }

    function calculateReferralBonus(uint256 _referralBonus, address _referredBy, address _playerAddr) private returns(bool) {

        address _secondReferrer;
        address _thirdReferrer;

        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _playerAddr
        )
        {
             
            if(firstReferrer[msg.sender] != 0x0000000000000000000000000000000000000000) {
                    _referredBy  = firstReferrer[msg.sender];
            }
            else {
                firstReferrer[msg.sender] = _referredBy;
            }

         
            if(firstReferrer[_referredBy] != 0x0000000000000000000000000000000000000000)
            {
                 _secondReferrer = firstReferrer[_referredBy];
                 
                if(firstReferrer[_secondReferrer] != 0x0000000000000000000000000000000000000000) {
                     _thirdReferrer = firstReferrer[_secondReferrer];

                     
                    referralBalance_[_thirdReferrer] = referralBalance_[_thirdReferrer].add(_referralBonus.mul(1).div(12));

                     
                    referralBalance_[_secondReferrer] = referralBalance_[_secondReferrer].add(_referralBonus.mul(3).div(12));

                     
                    referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));


                }
                 
                else {
                     
                    referralBalance_[_secondReferrer] = referralBalance_[_secondReferrer].add(_referralBonus.mul(3).div(12));
                     
                    referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));

                     
                    adminKeyVault_ = adminKeyVault_.add(_referralBonus.mul(1).div(12));

                }
            }  
            else {
                referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));

                 
                adminKeyVault_ = adminKeyVault_.add(_referralBonus.mul(4).div(12));
            }

            promoters[_referredBy][promoterDistRound] = promoters[_referredBy][promoterDistRound].add(_referralBonus.div(12).mul(100));
            addPromoter(_referredBy);
            return true;
    }

     
    else if(
             
            _referredBy == 0x0000000000000000000000000000000000000000 &&

             
            firstReferrer[msg.sender] != 0x0000000000000000000000000000000000000000

        )
        {
            _referredBy = firstReferrer[msg.sender];
            
            if(firstReferrer[_referredBy] != 0x0000000000000000000000000000000000000000)
            {
                 _secondReferrer = firstReferrer[_referredBy];
                 
                if(firstReferrer[_secondReferrer] != 0x0000000000000000000000000000000000000000) {
                     _thirdReferrer = firstReferrer[_secondReferrer];

                     
                    referralBalance_[_thirdReferrer] = referralBalance_[_thirdReferrer].add(_referralBonus.mul(1).div(12));

                     
                    referralBalance_[_secondReferrer] = referralBalance_[_secondReferrer].add(_referralBonus.mul(3).div(12));

                     
                    referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));

                }
                 
                else {
                     
                    referralBalance_[_secondReferrer] = referralBalance_[_secondReferrer].add(_referralBonus.mul(3).div(12));
                     
                    referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));

                     
                    adminKeyVault_ = adminKeyVault_.add(_referralBonus.mul(1).div(12));
                }
            }  
            else {
                referralBalance_[_referredBy] = referralBalance_[_referredBy].add(_referralBonus.mul(8).div(12));

                 
                adminKeyVault_ = adminKeyVault_.add(_referralBonus.mul(4).div(12));
            }
            promoters[_referredBy][promoterDistRound] = promoters[_referredBy][promoterDistRound].add(_referralBonus.div(12).mul(100));
            addPromoter(_referredBy);
            return true;
        }

        else {
             
            adminKeyVault_ = adminKeyVault_.add(_referralBonus);
        }
        return false;


     }

     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(msg.sender == _owner, "only admin can activate");


         
        require(rID_ == 0, "This is not the first round, please click startNextRound() to start new round");

         
        require(activated_ == false, "Golden Kingdom already activated");

         
        activated_ = true;

         
        rID_ = 1;
            round_[1].strt = now ;
            round_[1].end = now + rndInit_ ;
    }
 
 
 

    function getReferralBalance(address referralAddress)
    public
    view
    returns (uint256)
    {
    return referralBalance_[referralAddress];
    }

     
    function calcUnMaskedEarnings(address _pAddress, uint256 _rIDlast)
        private
        view
        returns(uint256, uint256)
    {
        uint256 _earnings =   (((round_[_rIDlast].mask).mul(plyrRnds_[_pAddress][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pAddress][_rIDlast].mask).sub(playerExtraEarnings_[_pAddress][_rIDlast]);
        uint256 _playerMaxEarningCap = (plyrRnds_[_pAddress][rID_].eth.mul(2)).div(keyPrice).mul(1000000000000000000);

        if
            (
               (_earnings.add(playerEarned_[_pAddress][_rIDlast]).add(plyr_[_pAddress].keys)) >= _playerMaxEarningCap
            )
            return(
                    _playerMaxEarningCap.sub((playerEarned_[_pAddress][_rIDlast]).add((plyr_[_pAddress].keys))),
                   _earnings.sub(_playerMaxEarningCap).add((playerEarned_[_pAddress][_rIDlast]).add((plyr_[_pAddress].keys)))
                  );
        else
            return(_earnings, 0);
    }

     
    function getPlayerInfoByAddress(address _playerAddr)
        public
        view
        returns( uint256, uint256, uint256, uint256, uint256)
    {

        
         

        uint256 _earnings;
        uint256 _extraEarnings;

        (_earnings, _extraEarnings) = calcUnMaskedEarnings(_playerAddr, plyr_[_playerAddr].lrnd);

        if(rID_ == plyr_[_playerAddr].lrnd)
        {
            return
            (  plyrRnds_[_playerAddr][rID_].keys,          
                plyr_[_playerAddr].win,                     
                (plyr_[_playerAddr].gen).add(_earnings),        
                referralBalance_[_playerAddr],                     
                plyrRnds_[_playerAddr][rID_].eth            
            );
        }
        else
        {
            return
            (  plyrRnds_[_playerAddr][rID_].keys,          
                plyr_[_playerAddr].win,                     
                (plyr_[_playerAddr].gen).add(_earnings).add(plyr_[_playerAddr].keys),        
                referralBalance_[_playerAddr],                     
                plyrRnds_[_playerAddr][rID_].eth            
            );
        }
    }

     
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt )
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt ).sub(_now) );
        else
            return(0);
    }

}

library DataStructs {


    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 genAmount;           
        uint256 potAmount;           
     }
    struct Player {
        address addr;        
        bytes32 name;        
        uint256 win;         
        uint256 gen;         
        uint256 lrnd;        
        uint256 keys;        
        uint256 eth;         
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
    }
    struct Round {
        address plyr;    
        uint256 playerCounter;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 treasure;     
        uint256 mask;    
    }
}


library NameFilter {
     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

         
        bool _hasNonNumber;

         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);

                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 ||
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                  
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }
}
