 

pragma solidity ^0.4.19;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

contract AccessControl {
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress || 
            msg.sender == ceoAddress || 
            msg.sender == cfoAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

 
contract TournamentInterface {
     
    function isTournament() public pure returns (bool);
    function isPlayerIdle(address _owner, uint256 _playerId) public view returns (bool);
}

 
contract BSBase is AccessControl {
     

     
    event Birth(address owner, uint32 playerId, uint16 typeId, uint8 attack, uint8 defense, uint8 stamina, uint8 xp, uint8 isKeeper, uint16 skillId);

     
     
    event Transfer(address from, address to, uint256 tokenId);

    struct Player {
        uint16 typeId;
        uint8 attack;
        uint8 defense;
        uint8 stamina;
        uint8 xp;
        uint8 isKeeper;
        uint16 skillId;
        uint8 isSkillOn;
    }

    Player[] players;
    uint256 constant commonPlayerCount = 10;
    uint256 constant totalPlayerSupplyLimit = 80000000;
    mapping (uint256 => address) public playerIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public playerIndexToApproved;
     
    ERC827 public joyTokenContract;
    TournamentInterface public tournamentContract;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
        ownershipTokenCount[_to]++;
         
        playerIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete playerIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

    function _createPlayer(
        address _owner,
        uint256 _typeId,
        uint256 _attack,
        uint256 _defense,
        uint256 _stamina,
        uint256 _xp,
        uint256 _isKeeper,
        uint256 _skillId
    )
        internal
        returns (uint256)
    {
        Player memory _player = Player({
            typeId: uint16(_typeId), 
            attack: uint8(_attack), 
            defense: uint8(_defense), 
            stamina: uint8(_stamina),
            xp: uint8(_xp),
            isKeeper: uint8(_isKeeper),
            skillId: uint16(_skillId),
            isSkillOn: 0
        });
        uint256 newPlayerId = players.push(_player) - 1;

        require(newPlayerId <= totalPlayerSupplyLimit);

         
        Birth(
            _owner,
            uint32(newPlayerId),
            _player.typeId,
            _player.attack,
            _player.defense,
            _player.stamina,
            _player.xp,
            _player.isKeeper,
            _player.skillId
        );

         
         
        _transfer(0, _owner, newPlayerId);

        return newPlayerId;
    }
}

 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) public view returns (bool);
}

 
contract BSOwnership is BSBase, ERC721 {

     
    string public constant name = "BitSoccer Player";
    string public constant symbol = "BSP";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
        bytes4(keccak256("transferFrom(address,address,uint256)")) ^
        bytes4(keccak256("tokensOfOwner(address)"));

     
     
     
    function supportsInterface(bytes4 _interfaceID) public view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToOwner[_tokenId] == _claimant;
    }

    function _isIdle(address _owner, uint256 _tokenId) internal view returns (bool) {
        return (tournamentContract == address(0) || tournamentContract.isPlayerIdle(_owner, _tokenId));
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return playerIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        playerIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_to != address(0));
         
        require(_to != address(this));

         
         
         
         

         
        require(_owns(msg.sender, _tokenId));
        require(_isIdle(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));
        require(_isIdle(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        require(_isIdle(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return players.length;
    }

     
     
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = playerIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount+commonPlayerCount);
        uint256 resultIndex = 0;

        uint256 playerId;
        for (playerId = 1; playerId <= commonPlayerCount; playerId++) {
            result[resultIndex] = playerId;
            resultIndex++;
        }

        if (tokenCount == 0) {
            return result;
        } else {
            uint256 totalPlayers = totalSupply();

            for (; playerId < totalPlayers; playerId++) {
                if (playerIndexToOwner[playerId] == _owner) {
                    result[resultIndex] = playerId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

 
interface RandomPlayerInterface {
     
    function isRandomPlayer() public pure returns (bool);

     
    function gen() public returns (uint256 typeId, uint256 attack, uint256 defense, uint256 stamina, uint256 xp, uint256 isKeeper, uint256 skillId);
}

contract BSMinting is BSOwnership {
         
     
    using SafeMath for uint256;
    RandomPlayerInterface public randomPlayer;

    uint256 constant public exchangePlayerTokenCount = 100 * (10**18);

    uint256 constant promoCreationPlayerLimit = 50000;

    uint256 public promoCreationPlayerCount;

    uint256 public promoEndTime;
    mapping (address => uint256) public userToken2PlayerCount;

    event ExchangePlayer(address indexed user, uint256 count);

    function BSMinting() public {
        promoEndTime = now + 2 weeks;
    }

    function setPromoEndTime(uint256 _endTime) external onlyCOO {
        promoEndTime = _endTime;
    }

     
     
    function setRandomPlayerAddress(address _address) external onlyCEO {
        RandomPlayerInterface candidateContract = RandomPlayerInterface(_address);

         
        require(candidateContract.isRandomPlayer());

         
        randomPlayer = candidateContract;
    }

    function createPromoPlayer(address _owner, uint256 _typeId, uint256 _attack, uint256 _defense,
            uint256 _stamina, uint256 _xp, uint256 _isKeeper, uint256 _skillId) external onlyCOO {
        address sender = _owner;
        if (sender == address(0)) {
             sender = cooAddress;
        }

        require(promoCreationPlayerCount < promoCreationPlayerLimit);
        promoCreationPlayerCount++;
        _createPlayer(sender, _typeId, _attack, _defense, _stamina, _xp, _isKeeper, _skillId);
    }

    function token2Player(address _sender, uint256 _count) public whenNotPaused returns (bool) {
        require(msg.sender == address(joyTokenContract) || msg.sender == _sender);
        require(_count > 0);
        uint256 totalTokenCount = _count.mul(exchangePlayerTokenCount);
        require(joyTokenContract.transferFrom(_sender, cfoAddress, totalTokenCount));

        uint256 typeId;
        uint256 attack;
        uint256 defense;
        uint256 stamina;
        uint256 xp;
        uint256 isKeeper;
        uint256 skillId;
        for (uint256 i = 0; i < _count; i++) {
            (typeId, attack, defense, stamina, xp, isKeeper, skillId) = randomPlayer.gen();
            _createPlayer(_sender, typeId, attack, defense, stamina, xp, isKeeper, skillId);
        }

        if (now < promoEndTime) {
            _onPromo(_sender, _count);
        }
        ExchangePlayer(_sender, _count);
        return true;
    }

    function _onPromo(address _sender, uint256 _count) internal {
        uint256 userCount = userToken2PlayerCount[_sender];
        uint256 userCountNow = userCount.add(_count);
        userToken2PlayerCount[_sender] = userCountNow;
        if (userCount == 0) {
            _createPlayer(_sender, 14, 88, 35, 58, 1, 0, 56);
        }
        if (userCount < 5 && userCountNow >= 5) {
            _createPlayer(_sender, 13, 42, 80, 81, 1, 0, 70);
        }
    }

    function createCommonPlayer() external onlyCOO returns (uint256)
    {
        require(players.length == 0);
        players.length++;

        uint16 commonTypeId = 1;
        address commonAdress = address(0);

        _createPlayer(commonAdress, commonTypeId++, 40, 12, 25, 1, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 16, 32, 39, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 30, 35, 13, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 22, 30, 24, 5, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 25, 14, 43, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 15, 40, 22, 5, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 17, 39, 25, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 41, 22, 13, 3, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 30, 31, 28, 1, 0, 0);
        _createPlayer(commonAdress, commonTypeId++, 13, 45, 11, 3, 1, 0);

        require(commonPlayerCount+1 == players.length);
        return commonPlayerCount;
    }
}

 
contract SaleClockAuctionInterface {
     
    function isSaleClockAuction() public pure returns (bool);
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller) external;
}

 
 
 
contract BSAuction is BSMinting {

     
    SaleClockAuctionInterface public saleAuction;

     
     
    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuctionInterface candidateContract = SaleClockAuctionInterface(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _playerId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _playerId));
        _approve(_playerId, saleAuction);
         
         
        saleAuction.createAuction(
            _playerId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
}

contract GlobalDefines {
    uint8 constant TYPE_SKILL_ATTRI_ATTACK = 0;
    uint8 constant TYPE_SKILL_ATTRI_DEFENSE = 1;
    uint8 constant TYPE_SKILL_ATTRI_STAMINA = 2;
    uint8 constant TYPE_SKILL_ATTRI_GOALKEEPER = 3;
}

 
contract PlayerInterface {
    function checkOwner(address _owner, uint32[11] _ids) public view returns (bool);
    function queryPlayerType(uint32[11] _ids) public view returns (uint32[11] playerTypes);
    function queryPlayer(uint32 _id) public view returns (uint16[8]);
    function queryPlayerUnAwakeSkillIds(uint32[11] _playerIds) public view returns (uint16[11] playerUnAwakeSkillIds);
    function tournamentResult(uint32[3][11][32] _playerAwakeSkills) public;
}

contract BSCore is GlobalDefines, BSAuction, PlayerInterface {

     

     
    function BSCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;
    }

     
     
    function setJOYTokenAddress(address _address) external onlyCOO {
         
        joyTokenContract = ERC827(_address);
    }

     
     
    function setTournamentAddress(address _address) external onlyCOO {
        TournamentInterface candidateContract = TournamentInterface(_address);

         
        require(candidateContract.isTournament());

         
        tournamentContract = candidateContract;
    }

    function() external {
        revert();
    }

    function withdrawJOYTokens() external onlyCFO {
        uint256 value = joyTokenContract.balanceOf(address(this));
        joyTokenContract.transfer(cfoAddress, value);
    }

     
     
    function getPlayer(uint256 _id)
        external
        view
        returns (
        uint256 typeId,
        uint256 attack,
        uint256 defense,
        uint256 stamina,
        uint256 xp,
        uint256 isKeeper,
        uint256 skillId,
        uint256 isSkillOn
    ) {
        Player storage player = players[_id];

        typeId = uint256(player.typeId);
        attack = uint256(player.attack);
        defense = uint256(player.defense);
        stamina = uint256(player.stamina);
        xp = uint256(player.xp);
        isKeeper = uint256(player.isKeeper);
        skillId = uint256(player.skillId);
        isSkillOn = uint256(player.isSkillOn);
    }

    function checkOwner(address _owner, uint32[11] _ids) public view returns (bool) {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            if ((_id <= 0 || _id > commonPlayerCount) && !_owns(_owner, _id)) {
                return false;
            }
        }
        return true;
    }

    function queryPlayerType(uint32[11] _ids) public view returns (uint32[11] playerTypes) {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            Player storage player = players[_id];
            playerTypes[i] = player.typeId;
        }
    }

    function queryPlayer(uint32 _id)
        public
        view
        returns (
        uint16[8]
    ) {
        Player storage player = players[_id];
        return [player.typeId, player.attack, player.defense, player.stamina, player.xp, player.isKeeper, player.skillId, player.isSkillOn];
    }

    function queryPlayerUnAwakeSkillIds(uint32[11] _playerIds)
        public
        view
        returns (
        uint16[11] playerUnAwakeSkillIds
    ) {
        for (uint256 i = 0; i < _playerIds.length; i++) {
            Player storage player = players[_playerIds[i]];
            if (player.skillId > 0 && player.isSkillOn == 0)
            {
                playerUnAwakeSkillIds[i] = player.skillId;
            }
        }
    }

    function tournamentResult(uint32[3][11][32] _playerAwakeSkills) public {
        require(msg.sender == address(tournamentContract));

        for (uint8 i = 0; i < 32; i++) {
            for (uint8 j = 0; j < 11; j++) {
                uint32 _id = _playerAwakeSkills[i][j][0];
                Player storage player = players[_id];
                if (player.skillId > 0 && player.isSkillOn == 0) {
                    uint32 skillType = _playerAwakeSkills[i][j][1];
                    uint8 skillAddAttri = uint8(_playerAwakeSkills[i][j][2]);

                    if (skillType == TYPE_SKILL_ATTRI_ATTACK) {
                        player.attack += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_DEFENSE) {
                        player.defense += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_STAMINA) {
                        player.stamina += skillAddAttri;
                        player.isSkillOn = 1;
                    }

                    if (skillType == TYPE_SKILL_ATTRI_GOALKEEPER && player.isKeeper == 0) {
                        player.isKeeper = 1;
                        player.isSkillOn = 1;
                    }
                }
            }
        }
    }
}