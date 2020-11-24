 

pragma solidity ^0.5.0;

 

contract Corpocracy {

     

    modifier onlyInitializedPlayers() {
        address _customerAddress = msg.sender;
        require(players[_customerAddress].wasInitialized);
        _;
    }

    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDividendHolders() {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }

    modifier whenNotPrerelease(){
        require(!isPrerelease);
        _;
    }

    modifier prereleaseLock(uint256 _incomingEther){
      if(isPrerelease && ((totalEtherBalance() - _incomingEther) <= PRERELEASE_QUOTA)){
        require(
          (players[msg.sender].totalEtherSpent + _incomingEther) <= PRERELEASE_MAX_PURCHASE
        );
      } else {
        isPrerelease = false;
      }
      _;
    }

     

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEther,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 etherEarned
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 etherWithdrawn
    );

     
    event onTransfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onClaimedTokens(
        address indexed customerAddress,
        uint256 tokens
    );

    event onWorldNodeRaid(
        address indexed customerAddress,
        uint8 worldNodeId
    );

    event onWorldNodeOwnerReveal(
        address indexed customerAddress,
        uint256 raidId,
        uint8 newOwnerId
    );

    event onPlayerChangedCorp(
        address indexed customerAddress,
        uint8 fromCorpId,
        uint8 toCorpId
    );

     

    struct Player {
        address addr;
        bool wasInitialized;
        uint8 corpId;
        uint256 tokenBalance;
        uint256 referralBalance;
        int256 payoutsTo;
        uint256[4] raidIds;
        uint256[4] raidStakes;
        uint256 totalEtherSpent;
    }

    struct Corporation {
        uint8 id;
        uint8 mainNodeId;
        uint8 totalValue;
        uint256 profitsPerShare;
        uint256 tokenSupply;
    }

    struct WorldNode {
        uint8 id;
        uint8 ownerId;
        uint8 value;
        bool isImmutable;
    }

    struct Raid {
        uint256 id;
        uint8 targetNodeId;
        uint8 attackingCorpId;
        bool wasSuccessful;
        bool hasBeenRevealed;
        uint256 defenderStakes;
        uint256 attackerStakes;
        uint256 endBlock;
    }

     

    uint8 constant public decimals = 18;

    uint256 constant internal tokenPrice = 0.000001 ether;
    uint256 constant internal magnitude = 2**64;

    uint256 constant internal PRERELEASE_MAX_PURCHASE = 1 ether;
    uint256 constant internal PRERELEASE_QUOTA = 20 ether;

    uint8 constant internal TRANSACTION_FEE_DIVIDENDS = 100;  
    uint8 constant internal TRANSACTION_FEE_REFERRAL = 200;  
    uint8 constant internal TRANSACTION_FEE_DEV = 25;  

    uint8 constant internal CORPORATIONS_COUNT = 2;
    uint8 constant internal NODES_COUNT = 14;
    uint8 constant internal PLAYER_SLOTS_COUNT = 4;

     

    string public name = "Corpocracy";
    string public symbol = "CRP";

    uint256 public stakingRequirement = 1000e18;
    uint256 public raidTimeLength = 12 hours;
    uint256 public secondsPerBlock = 15 seconds;

    bool public isPrerelease = true;

     

    mapping(address => bool) public administrators;
    uint256 public adminBalance = 0;

    mapping(uint8 => WorldNode) public worldNodes;
    mapping(uint8 => Corporation) public corporations;
    mapping(uint256 => Raid) public raids;

    mapping(address => Player) public players;

    address private lastAttacker;

    uint256[NODES_COUNT] public pendingRaidIds;
    uint256 internal nextRaidId = 1;

     

     

    function setAdministrator(address _identifier, bool _status)
        public
        onlyAdministrator()
    {
        administrators[_identifier] = _status;
    }

    function setStakingRequirement(uint256 _amountOfTokens)
        public
        onlyAdministrator()
    {
        stakingRequirement = _amountOfTokens;
    }

    function setName(string memory _name)
        public
        onlyAdministrator()
    {
        name = _name;
    }

    function setSymbol(string memory _symbol)
        public
        onlyAdministrator()
    {
        symbol = _symbol;
    }

    function setSecondsPerBlock(uint256 _seconds)
        public
        onlyAdministrator()
    {
        require(_seconds < raidTimeLength);
        secondsPerBlock = _seconds;
    }

    function setIsPrerelease(bool value)
        public
        onlyAdministrator()
    {
        isPrerelease = value;
    }

    function withdrawAdminBalance()
        public
        onlyAdministrator()
    {
        require(adminBalance > 0);

        address payable _customerAddress = msg.sender;
        uint256 _balance = adminBalance;
        adminBalance = 0;

        _customerAddress.transfer(_balance);
    }

    constructor()
    public
    {
        address _ownerAddress = msg.sender;
        administrators[_ownerAddress] = true;

         

         
        corporations[0] = Corporation({id: 0, mainNodeId: 0, totalValue: 50, profitsPerShare: 0, tokenSupply: 0});
        corporations[1] = Corporation({id: 1, mainNodeId: 1, totalValue: 50, profitsPerShare: 0, tokenSupply: 0});

         
         
        worldNodes[0] = WorldNode({id: 0, ownerId: 0, value: 20, isImmutable: true});
        worldNodes[1] = WorldNode({id: 1, ownerId: 1, value: 20, isImmutable: true});

         
         
        worldNodes[2] =  WorldNode({id: 2, ownerId: 0, value: 5, isImmutable: false});
        worldNodes[3] =  WorldNode({id: 3, ownerId: 0, value: 5, isImmutable: false});
        worldNodes[4] =  WorldNode({id: 4, ownerId: 0, value: 5, isImmutable: false});
        worldNodes[5] =  WorldNode({id: 5, ownerId: 0, value: 5, isImmutable: false});
        worldNodes[6] =  WorldNode({id: 6, ownerId: 0, value: 5, isImmutable: false});
        worldNodes[7] =  WorldNode({id: 7, ownerId: 0, value: 5, isImmutable: false});
         
        worldNodes[8] =  WorldNode({id: 8, ownerId: 1, value: 5, isImmutable: false});
        worldNodes[9] =  WorldNode({id: 9, ownerId: 1, value: 5, isImmutable: false});
        worldNodes[10] = WorldNode({id: 10, ownerId: 1, value: 5, isImmutable: false});
        worldNodes[11] = WorldNode({id: 11, ownerId: 1, value: 5, isImmutable: false});
        worldNodes[12] = WorldNode({id: 12, ownerId: 1, value: 5, isImmutable: false});
        worldNodes[13] = WorldNode({id: 13, ownerId: 1, value: 5, isImmutable: false});
    }

     

    function buy(address _referredBy)
        public
        payable
    returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }

    function()
        external
        payable
    {
        purchaseTokens(msg.value, address(0));
    }

    function purchaseTokens(uint256 _incomingEther, address _referredBy)
        internal
        prereleaseLock(_incomingEther)
    returns(uint256)
    {
        address _customerAddress = msg.sender;

        if (!players[_customerAddress].wasInitialized) {
          initializePlayer(_customerAddress);
        }

        Player storage _player = players[_customerAddress];
        Corporation storage _corp = corporations[_player.corpId];

        uint256 _devTax = _safeMul(_incomingEther, TRANSACTION_FEE_DEV) / 1000;
        uint256 _etherToWorld = _safeMul(_incomingEther, TRANSACTION_FEE_DIVIDENDS) / 1000;
        uint256 _referralBonus = _safeMul(_etherToWorld, TRANSACTION_FEE_REFERRAL) / 1000;
        uint256 _taxedEther = _safeSub(_incomingEther, _devTax + _etherToWorld);
        uint256 _amountOfTokens = _etherToTokens(_taxedEther);
        uint256 _totalTokenSupply = totalSupply();

        require(_amountOfTokens > 0 && (_safeAdd(_totalTokenSupply, _amountOfTokens) > _totalTokenSupply));

        _player.totalEtherSpent = _safeAdd(_player.totalEtherSpent, _incomingEther);
        adminBalance = _safeAdd(adminBalance, _devTax);

        if(
          _referredBy != address(0) &&
          _referredBy != _customerAddress &&
          players[_referredBy].tokenBalance >= stakingRequirement
        ){
          _etherToWorld = _safeSub(_etherToWorld, _referralBonus);
          players[_referredBy].referralBalance = _safeAdd(players[_referredBy].referralBalance, _referralBonus);
        }

        _corp.tokenSupply = _safeAdd(_corp.tokenSupply, _amountOfTokens);
        _player.tokenBalance = _safeAdd(_player.tokenBalance, _amountOfTokens);
        _player.payoutsTo += (int256) (_corp.profitsPerShare * _amountOfTokens);

        updateProfitsPerShare(_etherToWorld * magnitude);

        emit onTokenPurchase(_customerAddress, _incomingEther, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens)
        public
        onlyInitializedPlayers()
        onlyTokenHolders()
    {
        address _customerAddress = msg.sender;
        Player storage _player = players[_customerAddress];
        Corporation storage _corp = corporations[_player.corpId];

        require(_player.tokenBalance >= _amountOfTokens);

        uint256 _ether = _tokensToEther(_amountOfTokens);
        uint256 _devTax = _safeMul(_ether, TRANSACTION_FEE_DEV) / 1000;
        uint256 _etherToWorld = _safeMul(_ether, TRANSACTION_FEE_DIVIDENDS) / 1000;
        uint256 _taxedEther = _safeSub(_ether, _devTax + _etherToWorld);

        adminBalance = _safeAdd(adminBalance, _devTax);

        _corp.tokenSupply = _safeSub(_corp.tokenSupply, _amountOfTokens);
        _player.tokenBalance = _safeSub(_player.tokenBalance, _amountOfTokens);
        _player.payoutsTo -= (int256) (_corp.profitsPerShare * _amountOfTokens + (_taxedEther * magnitude));

        updateProfitsPerShare(_etherToWorld * magnitude);

        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedEther);
    }

    function withdraw()
        public
        onlyInitializedPlayers()
        onlyDividendHolders()
    {
        address payable _customerAddress = msg.sender;
        Player storage _player = players[_customerAddress];
        uint256 _dividends = dividendsOf(_customerAddress);

        _player.payoutsTo += (int256) (_dividends * magnitude);

        _dividends = _safeAdd(_dividends, _player.referralBalance);
        _player.referralBalance = 0;

        _customerAddress.transfer(_dividends);

        emit onWithdraw(_customerAddress, _dividends);
    }

    function revealWorldNodeOwnership(uint8 _nodeId)
        public
        onlyInitializedPlayers()
        whenNotPrerelease()
    {
        require(_nodeId < NODES_COUNT);

        address _customerAddress = msg.sender;
        uint256 _raidId = pendingRaidIds[_nodeId];

        require(_raidId > 0 && !raids[_raidId].hasBeenRevealed);
        require(block.number >= raids[_raidId].endBlock);

        Player storage _player = players[_customerAddress];
        Raid storage _raid = raids[_raidId];
        WorldNode storage _node = worldNodes[_nodeId];
        uint256 _defenderStakes = _raid.defenderStakes;
        uint256 _attackerStakes = _raid.attackerStakes;

        if (_player.corpId == _raid.attackingCorpId) {
            _attackerStakes = _safeAdd(_attackerStakes, _attackerStakes / 4);
        } else {
            _defenderStakes = _safeAdd(_defenderStakes, _defenderStakes / 4);
        }

        uint256 _totalStakes = _defenderStakes + _attackerStakes;
        uint256 _winningStake = _random(_raid.endBlock, 1, _totalStakes);

        _raid.hasBeenRevealed = true;
        _raid.wasSuccessful = (_winningStake > _defenderStakes);

        pendingRaidIds[_nodeId] = 0;

        if (_raid.wasSuccessful) {
          Corporation storage _originCorp = corporations[_node.ownerId];
          Corporation storage _targetCorp = corporations[_raid.attackingCorpId];

          _originCorp.totalValue = (uint8) (_safeSub(_originCorp.totalValue, _node.value));
          _node.ownerId = _raid.attackingCorpId;
          _targetCorp.totalValue = (uint8) (_safeAdd(_targetCorp.totalValue, _node.value));
        }

        emit onWorldNodeOwnerReveal(_customerAddress, _raidId, _node.ownerId);
    }

    function changePlayerCorporation(uint8 _toCorporationId)
        public
        onlyInitializedPlayers()
        whenNotPrerelease()
    {
        address _customerAddress = msg.sender;

        Player storage _player = players[_customerAddress];
        uint8 _fromCorporationId = _player.corpId;

        require(_toCorporationId < CORPORATIONS_COUNT);
        require(_toCorporationId != _fromCorporationId);

        bool _isRaiding = false;
        for (uint8 i = 0; i < PLAYER_SLOTS_COUNT; i++) {
          _isRaiding = (_isRaiding || _player.raidIds[i] != 0);
        }

        require(!_isRaiding);

        if(_player.tokenBalance > 0) {
          sell(_player.tokenBalance);
        }

        withdraw();

        _player.payoutsTo = 0;
        _player.corpId = _toCorporationId;

        emit onPlayerChangedCorp(_customerAddress, _fromCorporationId, _toCorporationId);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyInitializedPlayers()
        onlyTokenHolders()
        whenNotPrerelease()
    returns(bool)
    {
        address _customerAddress = msg.sender;

        require(_amountOfTokens <= players[_customerAddress].tokenBalance);

        Player storage _fromPlayer = players[_customerAddress];
        Player storage _toPlayer = players[_toAddress];

        if (!_toPlayer.wasInitialized) {
          initializePlayer(_toAddress);
        }

        Corporation storage _fromCorp = corporations[_fromPlayer.corpId];
        Corporation storage _toCorp = corporations[_toPlayer.corpId];

        if(myDividends(true) > 0) {
          withdraw();
        }

        uint256 _devTax = _safeMul(_amountOfTokens, TRANSACTION_FEE_DEV) / 1000;
        uint256 _tokenFee = _safeMul(_amountOfTokens, TRANSACTION_FEE_DIVIDENDS) / 1000;
        uint256 _taxedTokens = _safeSub(_amountOfTokens, _devTax + _tokenFee);
        uint256 _etherToWorld = _tokensToEther(_tokenFee);

        adminBalance = _safeAdd(adminBalance, _tokensToEther(_devTax));

         
        _fromPlayer.tokenBalance = _safeSub(_fromPlayer.tokenBalance, _amountOfTokens);
        _fromCorp.tokenSupply = _safeSub(_fromCorp.tokenSupply, _amountOfTokens);
        _toPlayer.tokenBalance = _safeAdd(_toPlayer.tokenBalance, _taxedTokens);
        _toCorp.tokenSupply = _safeAdd(_toCorp.tokenSupply, _taxedTokens);

        _fromPlayer.payoutsTo -= (int256) (_fromCorp.profitsPerShare * _amountOfTokens);
        _toPlayer.payoutsTo += (int256) (_toCorp.profitsPerShare * _taxedTokens);

        updateProfitsPerShare(_etherToWorld * magnitude);

        emit onTransfer(_customerAddress, _toAddress, _taxedTokens);

         
        return true;
    }

    function raidWorldNode(uint8 _worldNodeId, uint256 _stakes)
        public
        onlyInitializedPlayers()
        onlyTokenHolders()
        whenNotPrerelease()
    {
        address _customerAddress = msg.sender;
        Player storage _player = players[_customerAddress];
        Corporation storage _playerCorp = corporations[_player.corpId];

        require(_stakes > 0 && _player.tokenBalance >= _stakes);
        require(_worldNodeId < NODES_COUNT);
        require(worldNodes[_worldNodeId].isImmutable == false);
        require(_player.corpId != worldNodes[_worldNodeId].ownerId);

        if (pendingRaidIds[_worldNodeId] != 0) {
          require(block.number < raids[pendingRaidIds[_worldNodeId]].endBlock);
        }

        uint8 _raidSlot = getAvailableInvestmentSlot(_customerAddress, _worldNodeId);
        require(_raidSlot < PLAYER_SLOTS_COUNT);

        _playerCorp.tokenSupply = _safeSub(_playerCorp.tokenSupply, _stakes);
        _player.tokenBalance = _safeSub(_player.tokenBalance, _stakes);
        _player.payoutsTo -= (int256) (_playerCorp.profitsPerShare * _stakes);

         
        if (pendingRaidIds[_worldNodeId] == 0) {
          Raid memory _newRaid = Raid({
            id: nextRaidId,
            targetNodeId: _worldNodeId,
            attackingCorpId: _player.corpId,
            wasSuccessful: false,
            hasBeenRevealed: false,
            defenderStakes: 0,
            attackerStakes: 0,
            endBlock: (raidTimeLength / secondsPerBlock) + block.number
          });

          raids[_newRaid.id] = _newRaid;
          pendingRaidIds[_worldNodeId] = _newRaid.id;

          nextRaidId++;
        }

        Raid storage _raid = raids[pendingRaidIds[_worldNodeId]];

        _raid.attackerStakes = _safeAdd(_raid.attackerStakes, _stakes);
        _player.raidIds[_raidSlot] = _raid.id;
        _player.raidStakes[_raidSlot] = _safeAdd(_player.raidStakes[_raidSlot], _stakes);

        lastAttacker = _customerAddress;

        emit onWorldNodeRaid(_customerAddress, _worldNodeId);
    }

    function defendWorldNode(uint8 _worldNodeId, uint256 _stakes)
        public
        onlyInitializedPlayers()
        onlyTokenHolders()
        whenNotPrerelease()
    {
        address _customerAddress = msg.sender;
        Player storage _player = players[_customerAddress];
        Corporation storage _playerCorp = corporations[_player.corpId];

        require(_stakes > 0 && _player.tokenBalance >= _stakes);
        require(_worldNodeId < NODES_COUNT);
        require(pendingRaidIds[_worldNodeId] != 0);
        require(_player.corpId == worldNodes[_worldNodeId].ownerId);
        require(block.number < raids[pendingRaidIds[_worldNodeId]].endBlock);

        uint8 _raidSlot = getAvailableInvestmentSlot(_customerAddress, _worldNodeId);
        require(_raidSlot < PLAYER_SLOTS_COUNT);

        _playerCorp.tokenSupply = _safeSub(_playerCorp.tokenSupply, _stakes);
        _player.tokenBalance = _safeSub(_player.tokenBalance, _stakes);
        _player.payoutsTo -= (int256) (_playerCorp.profitsPerShare * _stakes);

        Raid storage _raid = raids[pendingRaidIds[_worldNodeId]];

        _raid.defenderStakes = _safeAdd(_raid.defenderStakes, _stakes);
        _player.raidIds[_raidSlot] = _raid.id;
        _player.raidStakes[_raidSlot] = _safeAdd(_player.raidStakes[_raidSlot], _stakes);

        emit onWorldNodeRaid(_customerAddress, _worldNodeId);
    }

    function claimRaidTokens()
        public
        onlyInitializedPlayers()
    {
        address _customerAddress = msg.sender;

        Player storage _player = players[_customerAddress];
        Corporation storage _corp = corporations[_player.corpId];

        uint256 _raidId = 0;
        uint256 _totalPrize = 0;
        uint256 _playerPrize = 0;
        uint256 _tokensToAdd = 0;

        for (uint8 i = 0; i < PLAYER_SLOTS_COUNT; i++) {
          _raidId = _player.raidIds[i];

          if (_raidId > 0 && raids[_raidId].hasBeenRevealed) {
            if (_player.corpId == raids[_raidId].attackingCorpId) {
                if (raids[_raidId].wasSuccessful) {
                  _totalPrize = raids[_raidId].defenderStakes / 4;
                  _playerPrize = _totalPrize * (_player.raidStakes[i] / raids[_raidId].attackerStakes);
                  _tokensToAdd = _safeAdd(_player.raidStakes[i], _playerPrize);

                } else {
                  _totalPrize = _player.raidStakes[i] / 4;
                  _tokensToAdd = _player.raidStakes[i] - _totalPrize;
                }
            } else {
                if (raids[_raidId].wasSuccessful) {
                  _totalPrize = _player.raidStakes[i] / 4;
                  _tokensToAdd = _player.raidStakes[i] - _totalPrize;

                } else {
                  _totalPrize = raids[_raidId].attackerStakes / 4;
                  _playerPrize = _totalPrize * (_player.raidStakes[i] / raids[_raidId].defenderStakes);
                  _tokensToAdd = _safeAdd(_player.raidStakes[i], _playerPrize);
                }
            }

            _player.raidIds[i] = 0;
            _player.raidStakes[i] = 0;

            _corp.tokenSupply = _safeAdd(_corp.tokenSupply, _tokensToAdd);
            _player.tokenBalance = _safeAdd(_player.tokenBalance, _tokensToAdd);

            _player.payoutsTo += (int256) (_corp.profitsPerShare * _tokensToAdd);
          }
        }

        emit onClaimedTokens(_customerAddress, _tokensToAdd);
    }

     

    function totalEtherBalance()
        public
        view
    returns(uint256)
    {
        return address(this).balance;
    }

    function totalSupply()
        public
        view
    returns(uint256)
    {
        return _safeAdd(corporations[0].tokenSupply, corporations[1].tokenSupply);
    }

    function myTokens()
        public
        view
    returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus)
        public
        view
    returns(uint256)
    {
        address _customerAddress = msg.sender;
        Player storage _player = players[_customerAddress];

        return _includeReferralBonus? dividendsOf(_customerAddress) + _player.referralBalance : dividendsOf(_customerAddress);
    }

    function balanceOf(address _customerAddress)
        public
        view
    returns(uint256)
    {
        return players[_customerAddress].tokenBalance;
    }

    function dividendsOf(address _customerAddress)
        view
        public
    returns(uint256)
    {
        Player storage _player = players[_customerAddress];
        Corporation storage _corp = corporations[_player.corpId];
        int256 _profits = (int256)(_corp.profitsPerShare * _player.tokenBalance) - _player.payoutsTo;

        if (_profits > 0) {
          return (uint256) (_profits) / magnitude;
        } else {
          return 0;
        }
    }

    function getSellPrice(uint256 _tokensToSell)
        public
        view
    returns(uint256)
    {
        uint256 _ether = _tokensToEther(_tokensToSell);
        uint256 _devFee = _safeMul(_ether, TRANSACTION_FEE_DEV) / 1000;
        uint256 _etherToWorld = _safeMul(_ether, TRANSACTION_FEE_DIVIDENDS) / 1000;
        uint256 _taxedEther = _safeSub(_ether, _devFee + _etherToWorld);
        return _taxedEther;
    }

    function getBuyPrice(uint256 _tokensToBuy)
        public
        view
    returns(uint256)
    {
        uint256 _ether = _tokensToEther(_tokensToBuy) / (1 - (TRANSACTION_FEE_DEV + TRANSACTION_FEE_DIVIDENDS) / 1000);
        return _ether;
    }

    function getTokensReceived(uint256 _etherToSpend)
        public
        view
    returns(uint256)
    {
      uint256 _devFee = _safeMul(_etherToSpend, TRANSACTION_FEE_DEV) / 1000;
      uint256 _etherToWorld = _safeMul(_etherToSpend, TRANSACTION_FEE_DIVIDENDS) / 1000;
      uint256 _taxedEther = _safeSub(_etherToSpend, _devFee + _etherToWorld);
      uint256 _tokensReceived = _etherToTokens(_taxedEther);

      return _tokensReceived;
    }

     
    function getPlayerData(address _customerAddress)
        external
        view
    returns(bool, uint8, uint256, uint256, uint256, uint256[] memory, uint256[] memory, uint256)
    {
        Player storage _player = players[_customerAddress];
        uint256 _dividends = dividendsOf(_customerAddress);

        uint256[] memory _raidIds = new uint256[](PLAYER_SLOTS_COUNT);
        uint256[] memory _raidStakes = new uint256[](PLAYER_SLOTS_COUNT);

        for (uint8 i = 0; i < PLAYER_SLOTS_COUNT; i++) {
          _raidIds[i] = _player.raidIds[i];
          _raidStakes[i] = _player.raidStakes[i];
        }

        return (
          _player.wasInitialized,
          _player.corpId,
          _player.tokenBalance,
          _dividends,
          _player.referralBalance,
          _raidIds,
          _raidStakes,
          _player.totalEtherSpent
        );
    }

     
    function getWorldState()
        external
        view
    returns(bool, uint8[] memory, uint256[] memory)
    {
        uint8[] memory _nodeOwners = new uint8[](NODES_COUNT);
        uint256[] memory _pendingRaidIds = new uint256[](NODES_COUNT);

        for (uint8 i = 0; i < NODES_COUNT; i++) {
          _nodeOwners[i] = worldNodes[i].ownerId;
          _pendingRaidIds[i] = pendingRaidIds[i];
        }

        return (isPrerelease, _nodeOwners, _pendingRaidIds);
    }

     
    function getRaidState(uint256 _raidId)
        external
        view
    returns(uint256, uint8, uint8, bool, bool, uint256, uint256, uint256)
    {
        Raid storage _raid = raids[_raidId];
        uint256 _blocksLeft = 0;

        if (block.number < _raid.endBlock) {
          _blocksLeft = (_raid.endBlock - block.number);
        }

        return (
          _raid.id,
          _raid.targetNodeId,
          _raid.attackingCorpId,
          _raid.wasSuccessful,
          _raid.hasBeenRevealed,
          _raid.defenderStakes,
          _raid.attackerStakes,
          _blocksLeft
        );
    }

     

    function initializePlayer(address _customerAddress)
        internal
    {
        Player storage _player = players[_customerAddress];

        require(!_player.wasInitialized);

        _player.wasInitialized = true;
        _player.addr = _customerAddress;
        _player.corpId = corporations[0].tokenSupply <= corporations[1].tokenSupply? 0 : 1;
    }

    function updateProfitsPerShare(uint256 _incomingEther)
        internal
    {
        require(_incomingEther > 0);

        uint256 _corp0ProfitsTotal = 0;
        uint256 _corp0Adjustment = 0;
        uint256 _newProfitsPerShare = 0;

        Corporation storage _corp0 = corporations[0];
        Corporation storage _corp1 = corporations[1];

        uint256 _totalTokenSupply = totalSupply();

        if (_corp0.tokenSupply > 0) {
          _corp0ProfitsTotal = _safeMul(_incomingEther, _corp0.tokenSupply) / _totalTokenSupply;

          if (_corp0.totalValue > 50) {
            _corp0Adjustment = _safeMul(_incomingEther - _corp0ProfitsTotal, _corp0.totalValue - 50) / 50;
            _corp0ProfitsTotal = _safeAdd(_corp0ProfitsTotal, _corp0Adjustment);
          } else {
            _corp0Adjustment = _safeMul(_corp0ProfitsTotal, 50 - _corp0.totalValue) / 50;
            _corp0ProfitsTotal = _safeSub(_corp0ProfitsTotal, _corp0Adjustment);
          }

          _newProfitsPerShare = _corp0ProfitsTotal / _corp0.tokenSupply;
          _corp0.profitsPerShare = _safeAdd(_corp0.profitsPerShare, _newProfitsPerShare);

        } else {
          _corp0ProfitsTotal = 0;
          _corp0.profitsPerShare = 0;
        }

        if (_corp1.tokenSupply > 0) {
          _newProfitsPerShare = _safeSub(_incomingEther, _corp0ProfitsTotal) / _corp1.tokenSupply;
          _corp1.profitsPerShare = _safeAdd(_corp1.profitsPerShare, _newProfitsPerShare);
        } else {
          _corp1.profitsPerShare = 0;
        }
    }

    function getAvailableInvestmentSlot(address _customerAddress, uint8 _worldNodeId)
        internal
        view
        returns(uint8)
    {
      Player storage _player = players[_customerAddress];

      uint256 _raidId = 0;
      uint8 _freeSlotIndex = PLAYER_SLOTS_COUNT;

      for (uint8 i = 0; i < PLAYER_SLOTS_COUNT; i++) {
        _raidId = _player.raidIds[i];

        if (_raidId > 0) {
          if (raids[_raidId].targetNodeId == _worldNodeId) {
            return i;
          }

        } else {
          _freeSlotIndex = i;
        }
      }

      return _freeSlotIndex;
    }

    function _etherToTokens(uint256 _ether)
        internal
        view
    returns(uint256)
    {
        uint256 _tokensReceived = (_ether / tokenPrice) * 1e18;
        return _tokensReceived;
    }

    function _tokensToEther(uint256 _tokens)
        internal
        view
    returns(uint256)
    {
        uint256 _etherReceived = (_tokens / 1e18) * tokenPrice;
        return _etherReceived;
    }

    function _getRNGTargetBlock(uint256 _block)
        internal
        view
    returns(uint256){
      uint256 currentBlock = block.number;
      uint256 target = currentBlock - (currentBlock % 256) + (_block % 256);
      if (target >= currentBlock) {
        return (target - 256);
      }
      return target;
    }

    function _random(uint256 _targetBlock, uint256 _min, uint256 _max)
        internal
        view
    returns (uint256)
    {
      uint256 _rngTargetBlock = _getRNGTargetBlock(_targetBlock);
      uint256 _rngHash = uint256(keccak256(abi.encodePacked(blockhash(_rngTargetBlock)))) + uint256(lastAttacker);

      return _rngHash % (_max - _min) + _min;
    }

     

    function _safeMul(uint256 a, uint256 b)
        internal
        pure
    returns (uint256)
    {
      if (a == 0) {
        return 0;
      }

      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function _safeSub(uint256 a, uint256 b)
        internal
        pure
    returns (uint256)
    {
      assert(b <= a);
      return a - b;
    }

    function _safeAdd(uint256 a, uint256 b)
        internal
        pure
    returns (uint256)
    {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}