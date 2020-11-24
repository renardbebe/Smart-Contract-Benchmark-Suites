 

pragma solidity^0.4.21;

contract EtheraffleInterface {
    uint public tktPrice;
    function getUserNumEntries(address _entrant, uint _week) public view returns (uint) {}
}

contract LOTInterface {
    function transfer(address _to, uint _value) public {}
    function balanceOf(address _owner) public view returns (uint) {}
}
 
contract EtheraffleLOTPromo {
    
    bool    public isActive;
    uint    constant public RAFEND     = 500400;      
    uint    constant public BIRTHDAY   = 1500249600;  
    uint    constant public ICOSTART   = 1522281600;  
    uint    constant public TIER1END   = 1523491200;  
    uint    constant public TIER2END   = 1525305600;  
    uint    constant public TIER3END   = 1527724800;  
    address constant public ETHERAFFLE = 0x97f535e98cf250CDd7Ff0cb9B29E4548b609A0bd;
    
    LOTInterface LOTContract;
    EtheraffleInterface etheraffleContract;

     
    mapping (address => mapping (uint => bool)) public claimed;
    
    event LogActiveStatus(bool currentStatus, uint atTime);
    event LogTokenDeposit(address fromWhom, uint tokenAmount, bytes data);
    event LogLOTClaim(address whom, uint howMany, uint inWeek, uint atTime);
     
    modifier onlyEtheraffle() {
        require(msg.sender == ETHERAFFLE);
        _;
    }
     
    function EtheraffleLOTPromo() public {
        isActive           = true;
        LOTContract        = LOTInterface(0xAfD9473dfe8a49567872f93c1790b74Ee7D92A9F);
        etheraffleContract = EtheraffleInterface(0x4251139bF01D46884c95b27666C9E317DF68b876);
    }
     
    function redeem(uint _weekNo) public {
        uint week    = _weekNo == 0 ? getWeek() : _weekNo;
        uint entries = getNumEntries(msg.sender, week);
        require(
            !claimed[msg.sender][week] &&
            entries > 0 &&
            isActive
            );
        uint amt = getPromoLOTEarnt(entries);
        if (getLOTBalance(this) < amt) {
            isActive = false;
            emit LogActiveStatus(false, now);
            return;
        }
        claimed[msg.sender][week] = true;
        LOTContract.transfer(msg.sender, amt);
        emit LogLOTClaim(msg.sender, amt, week, now);
    }
     
    function getNumEntries(address _address, uint _weekNo) public view returns (uint) {
        uint week = _weekNo == 0 ? getWeek() : _weekNo;
        return etheraffleContract.getUserNumEntries(_address, week);
    }
     
    function togglePromo(bool _status) public onlyEtheraffle {
        isActive = _status;
        emit LogActiveStatus(_status, now);
    }
     
    function getWeek() public view returns (uint) {
        uint curWeek = (now - BIRTHDAY) / 604800;
        if (now - ((curWeek * 604800) + BIRTHDAY) > RAFEND) curWeek++;
        return curWeek;
    }
     
    function tokenFallback(address _from, uint256 _value, bytes _data) external {
        if (_value > 0) emit LogTokenDeposit(_from, _value, _data);
    }
     
    function getLOTBalance(address _address) internal view returns (uint) {
        return LOTContract.balanceOf(_address);
    }
     
    function hasRedeemed(address _address, uint _weekNo) public view returns (bool) {
        uint week = _weekNo == 0 ? getWeek() : _weekNo;
        return claimed[_address][week];
    }
     
    function getTktPrice() public view returns (uint) {
        return etheraffleContract.tktPrice();
    }
     
    function getRate() public view returns (uint) {
        if (now <  ICOSTART) return 110000 * 10 ** 6;
        if (now <= TIER1END) return 100000 * 10 ** 6;
        if (now <= TIER2END) return 90000  * 10 ** 6;
        if (now <= TIER3END) return 80000  * 10 ** 6;
        else return 0;
    }
     
    function getPromoLOTEarnt(uint _entries) public view returns (uint) {
        return (_entries * getRate() * getTktPrice()) / (1 * 10 ** 18);
    }
     
    function scuttle() external onlyEtheraffle {
        LOTContract.transfer(ETHERAFFLE, LOTContract.balanceOf(this));
        selfdestruct(ETHERAFFLE);
    }
}