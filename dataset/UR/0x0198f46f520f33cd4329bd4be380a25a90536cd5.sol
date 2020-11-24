 

 


pragma solidity 0.4.25;
pragma experimental "v0.5.0";


 




 
contract ERC20Token {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function approve(address spender, uint quantity) public returns (bool);
    function transfer(address to, uint quantity) public returns (bool);
    function transferFrom(address from, address to, uint quantity) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint quantity);
    event Approval(address indexed owner, address indexed spender, uint quantity);

}
 


 
contract Owned {
    address public owner;
    address public nominatedOwner;

     
    constructor(address _owner)
        public
    {
        require(_owner != address(0), "Null owner address.");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

     
    function nominateNewOwner(address _owner)
        public
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

     
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "Not nominated.");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

 
 






 
contract Pausable is Owned {

    bool public paused;
    
     
    function _pause()
        internal
    {
        if (!paused) {
            paused = true;
            emit Paused();
        }
    }

     
    function pause() 
        public
        onlyOwner
    {
        _pause();
    }

     
    function _unpause()
        internal
    {
        if (paused) {
            paused = false;
            emit Unpaused();
        }
    }

     
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    modifier onlyPaused {
        require(paused, "Contract must be paused.");
        _;
    }

    modifier pausable {
        require(!paused, "Contract must not be paused.");
        _;
    }

    event Paused();
    event Unpaused();

}
 






 
contract SelfDestructible is Owned {

    uint public selfDestructInitiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

     
    constructor(address _beneficiary)
        public
    {
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

     
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be the zero address.");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

     
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        require(!selfDestructInitiated, "Self-destruct already initiated.");
        selfDestructInitiationTime = now;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

     
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self-destruct not yet initiated.");
        selfDestructInitiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

     
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self-destruct not yet initiated.");
        require(selfDestructInitiationTime + SELFDESTRUCT_DELAY < now, "Self-destruct delay has not yet elapsed.");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

 


 
contract PlayChip is ERC20Token, Owned, Pausable, SelfDestructible {

     
    constructor(uint _totalSupply, address _owner)
        Owned(_owner)
        Pausable()
        SelfDestructible(_owner)
        public
    {
        _pause();
        name = "PlayChip";
        symbol = "PLA";
        decimals = 18;
        totalSupply = _totalSupply;
        balanceOf[this] = totalSupply;
        emit Transfer(address(0), this, totalSupply);
    }


     

    modifier requireSameLength(uint a, uint b) {
        require(a == b, "Input array lengths differ.");
        _;
    }

     
    modifier pausableIfNotSelfDestructing {
        require(!paused || selfDestructInitiated, "Contract must not be paused.");
        _;
    }

     
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x, "Safe sub failed.");
        return x - y;
    }


     

     
    function _transfer(address from, address to, uint quantity)
        internal
        returns (bool)
    {
        require(to != address(0), "Transfers to 0x0 disallowed.");
        balanceOf[from] = safeSub(balanceOf[from], quantity);  
        balanceOf[to] += quantity;
        emit Transfer(from, to, quantity);
        return true;

         
    }

     
    function transfer(address to, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
        return _transfer(msg.sender, to, quantity);
    }

     
    function approve(address spender, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
        require(spender != address(0), "Approvals for 0x0 disallowed.");
        allowance[msg.sender][spender] = quantity;
        emit Approval(msg.sender, spender, quantity);
        return true;
    }

     
    function transferFrom(address from, address to, uint quantity)
        public
        pausableIfNotSelfDestructing
        returns (bool)
    {
         
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], quantity);
        return _transfer(from, to, quantity);
    }


     

     
    function _batchTransfer(address sender, address[] recipients, uint[] quantities)
        internal
        requireSameLength(recipients.length, quantities.length)
        returns (bool)
    {
        uint length = recipients.length;
        for (uint i = 0; i < length; i++) {
            _transfer(sender, recipients[i], quantities[i]);
        }
        return true;
    }

     
    function batchTransfer(address[] recipients, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        returns (bool)
    {
        return _batchTransfer(msg.sender, recipients, quantities);
    }

     
    function batchApprove(address[] spenders, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        requireSameLength(spenders.length, quantities.length)
        returns (bool)
    {
        uint length = spenders.length;
        for (uint i = 0; i < length; i++) {
            approve(spenders[i], quantities[i]);
        }
        return true;
    }

     
    function batchTransferFrom(address[] spenders, address[] recipients, uint[] quantities)
        external
        pausableIfNotSelfDestructing
        requireSameLength(spenders.length, recipients.length)
        requireSameLength(recipients.length, quantities.length)
        returns (bool)
    {
        uint length = spenders.length;
        for (uint i = 0; i < length; i++) {
            transferFrom(spenders[i], recipients[i], quantities[i]);
        }
        return true;
    }


     

     
    function contractBatchTransfer(address[] recipients, uint[] quantities)
        external
        onlyOwner
        returns (bool)
    {
        return _batchTransfer(this, recipients, quantities);
    }

}