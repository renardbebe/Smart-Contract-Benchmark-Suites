 

pragma solidity ^0.5.0;

 
contract Remember43 {
    
    mapping(uint16 => Victim) public victims;
    mapping(address => bool) public isContributor;
    
    uint16 public victimsCount;
    address owner;
    uint timeout = 20 minutes;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyContributor {
        require(isContributor[msg.sender]);
        _;
    }
    
    struct Victim {
        uint16 idx;
        string name;
        string addr;
        uint createTime;
    }
    
    event contributorSet(address indexed contributor, bool state);
    event victimAdded(uint16 idx, string name, string addr, uint createTime);
    event victimModified(uint16 idx, string name, string addr, uint createTime);

    constructor() public {
        owner = msg.sender;
    }
    
     
    function setContributor(address _addr, bool _state) onlyOwner public {
        isContributor[_addr] = _state;
        emit contributorSet(_addr, isContributor[_addr]);
    }
    
     
    function addVictim(string memory _name, string memory _addr) onlyContributor public {
        victimsCount++;
        Victim memory vt = Victim(victimsCount, _name, _addr, now);
        victims[victimsCount] = vt;
        emit victimAdded(victims[victimsCount].idx, victims[victimsCount].name, victims[victimsCount].addr, victims[victimsCount].createTime);
    }
    
     
    function getVictim(uint16 _idx) public view returns(uint16, string memory, string memory) {
        Victim memory vt = victims[_idx]; 
        return (_idx, vt.name, vt.addr); 
    }
    
     
    function modifyVictim(uint16 _idx, string memory _name, string memory _addr) onlyContributor public {
        require(victims[_idx].createTime + timeout > now);
        victims[_idx].name = _name;
        victims[_idx].addr = _addr;
        emit victimModified(victims[_idx].idx, victims[_idx].name, victims[_idx].addr, victims[_idx].createTime);
        
    }
}