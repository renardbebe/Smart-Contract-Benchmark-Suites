 

pragma solidity ^0.4.25;

 

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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract CryptoEngineerOldInterface {
    address public gameSponsor;
    uint256 public gameSponsorPrice;
    
    function getBoosterData(uint256  ) public view returns (address  ,uint256  , uint256  ) {}
    function calculateCurrentVirus(address  ) external view returns(uint256  ) {}
    function getPlayerData(address  ) external view returns(uint256  , uint256  , uint256  , uint256  , uint256  , uint256  , uint256[8]  , uint256  , uint256  ) {}
}
interface CryptoArenaOldInterface {
    function getData(address _addr) 
    external
    view
    returns(
        uint256  ,
        uint256  ,
        uint256  ,
        bool     ,
         
        uint256  , 
         
        uint256  
    );
}

contract CryptoEngineerNewInterface {
    mapping(uint256 => EngineerData) public engineers;
     struct EngineerData {
            uint256 basePrice;
            uint256 baseETH;
            uint256 baseResearch;
            uint256 limit;
     }

    function setBoostData(uint256  , address  , uint256  , uint256   ) external pure {}
    function setPlayerEngineersCount( address  , uint256  , uint256   ) external pure {}
    function setGameSponsorInfo( address  , uint256   ) external pure {}
    function setPlayerResearch( address  , uint256   ) external pure {}
    function setPlayerVirusNumber( address  , uint256   ) external pure {}
    function setPlayerLastUpdateTime( address  ) external pure {}
}
interface CryptoArenaNewInterface {
    function setPlayerVirusDef(address  , uint256  ) external pure; 
}
contract CryptoLoadEngineerOldData {
     
	address public administrator;
    bool public loaded;

    mapping(address => bool) public playersLoadOldData;
   
    CryptoEngineerNewInterface public EngineerNew;
    CryptoEngineerOldInterface public EngineerOld;    
    CryptoArenaNewInterface    public ArenaNew;
    CryptoArenaOldInterface    public ArenaOld;

    modifier isAdministrator()
    {
        require(msg.sender == administrator);
        _;
    }

     
     
     
    constructor() public {
        administrator = msg.sender;
         
       EngineerNew = CryptoEngineerNewInterface(0xd7afbf5141a7f1d6b0473175f7a6b0a7954ed3d2);
       EngineerOld = CryptoEngineerOldInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
       ArenaNew    = CryptoArenaNewInterface(0x77c9acc811e4cf4b51dc3a3e05dc5d62fa887767);
       ArenaOld    = CryptoArenaOldInterface(0xce6c5ef2ed8f6171331830c018900171dcbd65ac);

    }

    function () public payable
    {
    }
     
        function isContractMiniGame() public pure returns(bool _isContractMiniGame)
        {
        	_isContractMiniGame = true;
        }
     
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
    function loadEngineerOldData() public isAdministrator 
    {
        require(loaded == false);
        loaded = true;
        address gameSponsor      = EngineerOld.gameSponsor();
        uint256 gameSponsorPrice = EngineerOld.gameSponsorPrice();
        EngineerNew.setGameSponsorInfo(gameSponsor, gameSponsorPrice);
        for(uint256 idx = 0; idx < 5; idx++) {
            mergeBoostData(idx);
        }
    }
    function mergeBoostData(uint256 idx) private
    {
        address owner;
        uint256 boostRate;
        uint256 basePrice;
        (owner, boostRate, basePrice) = EngineerOld.getBoosterData(idx);

        if (owner != 0x0) EngineerNew.setBoostData(idx, owner, boostRate, basePrice);
    }
    function loadOldData() public 
    {
        require(tx.origin == msg.sender);
        require(playersLoadOldData[msg.sender] == false);

        playersLoadOldData[msg.sender] = true;

        uint256[8] memory engineersCount; 
        uint256 virusDef;
        uint256 researchPerDay;
        
        uint256 virusNumber = EngineerOld.calculateCurrentVirus(msg.sender);
         
        (, , , , researchPerDay, , engineersCount, , ) = EngineerOld.getPlayerData(msg.sender);

        (virusDef, , , , , ) = ArenaOld.getData(msg.sender);

        virusNumber = SafeMath.sub(virusNumber, SafeMath.mul(researchPerDay, 432000));
        uint256 research = 0;
        uint256 baseResearch = 0;

        for (uint256 idx = 0; idx < 8; idx++) {
            if (engineersCount[idx] > 0) {
                (, , baseResearch, ) = EngineerNew.engineers(idx);
                EngineerNew.setPlayerEngineersCount(msg.sender, idx, engineersCount[idx]);
                research = SafeMath.add(research, SafeMath.mul(engineersCount[idx], baseResearch));
            }    
        }
        EngineerNew.setPlayerLastUpdateTime(msg.sender);
        if (research > 0)    EngineerNew.setPlayerResearch(msg.sender, research);
        
        if (virusNumber > 0) EngineerNew.setPlayerVirusNumber(msg.sender, virusNumber);

        if (virusDef > 0)    ArenaNew.setPlayerVirusDef(msg.sender, virusDef);
    }

}