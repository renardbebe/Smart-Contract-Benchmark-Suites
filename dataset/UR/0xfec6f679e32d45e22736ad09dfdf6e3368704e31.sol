 

pragma solidity ^0.5.0;

contract Lock {
     
     
    constructor (address owner, uint256 unlockTime) public payable {
        assembly {
            sstore(0x00, owner)
            sstore(0x01, unlockTime)
        }
    }
    
     
    function () external payable {  
        assembly {
            switch gt(timestamp, sload(0x01))
            case 0 { revert(0, 0) }
            case 1 {
                switch call(gas, sload(0x00), balance(address), 0, 0, 0, 0)
                case 0 { revert(0, 0) }
            }
        }
    }
}

contract Lockdrop {
    enum Term {
        ThreeMo,
        SixMo,
        TwelveMo
    }
     
    uint256 constant public LOCK_DROP_PERIOD = 1 days * 92;  
    uint256 public LOCK_START_TIME;
    uint256 public LOCK_END_TIME;
     
    event Locked(address indexed owner, uint256 eth, Lock lockAddr, Term term, bytes edgewareAddr, bool isValidator, uint time);
    event Signaled(address indexed contractAddr, bytes edgewareAddr, uint time);
    
    constructor(uint startTime) public {
        LOCK_START_TIME = startTime;
        LOCK_END_TIME = startTime + LOCK_DROP_PERIOD;
    }

     
    function lock(Term term, bytes calldata edgewareAddr, bool isValidator)
        external
        payable
        didStart
        didNotEnd
    {
        uint256 eth = msg.value;
        address owner = msg.sender;
        uint256 unlockTime = unlockTimeForTerm(term);
         
        Lock lockAddr = (new Lock).value(eth)(owner, unlockTime);
         
        assert(address(lockAddr).balance >= msg.value);
        emit Locked(owner, eth, lockAddr, term, edgewareAddr, isValidator, now);
    }

     
    function signal(address contractAddr, uint32 nonce, bytes calldata edgewareAddr)
        external
        didStart
        didNotEnd
        didCreate(contractAddr, msg.sender, nonce)
    {
        emit Signaled(contractAddr, edgewareAddr, now);
    }

    function unlockTimeForTerm(Term term) internal view returns (uint256) {
        if (term == Term.ThreeMo) return now + 92 days;
        if (term == Term.SixMo) return now + 183 days;
        if (term == Term.TwelveMo) return now + 365 days;
        
        revert();
    }

     
    modifier didStart() {
        require(now >= LOCK_START_TIME);
        _;
    }

     
    modifier didNotEnd() {
        require(now <= LOCK_END_TIME);
        _;
    }

     
    function addressFrom(address _origin, uint32 _nonce) public pure returns (address) {
        if(_nonce == 0x00)     return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, byte(0x80))))));
        if(_nonce <= 0x7f)     return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, uint8(_nonce))))));
        if(_nonce <= 0xff)     return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xd7), byte(0x94), _origin, byte(0x81), uint8(_nonce))))));
        if(_nonce <= 0xffff)   return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xd8), byte(0x94), _origin, byte(0x82), uint16(_nonce))))));
        if(_nonce <= 0xffffff) return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xd9), byte(0x94), _origin, byte(0x83), uint24(_nonce))))));
        return address(uint160(uint256(keccak256(abi.encodePacked(byte(0xda), byte(0x94), _origin, byte(0x84), uint32(_nonce))))));  
    }

     
    modifier didCreate(address target, address parent, uint32 nonce) {
         
        if (target == parent) {
            _;
        } else {
            require(target == addressFrom(parent, nonce));
            _;
        }
    }
}