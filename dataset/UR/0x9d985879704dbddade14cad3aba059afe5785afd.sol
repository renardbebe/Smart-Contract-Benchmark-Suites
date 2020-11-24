 

pragma solidity ^0.4.21;


contract Owner {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owner(address _owner) public {
        owner = _owner;
    }

    function changeOwner(address _newOwnerAddr) public onlyOwner {
        require(_newOwnerAddr != address(0));
        owner = _newOwnerAddr;
    }
}


 
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


contract Extradecoin is Owner {
    using SafeMath for uint256;

    string public constant name = "EXTRADECOIN";
    string public constant symbol = "ETE";
    uint public constant decimals = 18;
    uint256 constant public totalSupply = 250000000 * 10 ** 18;  
  
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    address public adminAddress;
    address public walletAddress;
    address public founderAddress;
    address public advisorAddress;
    
    mapping(address => uint256) public totalInvestedAmountOf;

    uint constant lockPeriod1 = 3 years;  
    uint constant lockPeriod2 = 1 years;  
    uint constant lockPeriod3 = 90 days;  
   
    uint constant NOT_SALE = 0;  
    uint constant IN_ICO = 1;  
    uint constant END_SALE = 2;  

    uint256 public constant salesAllocation = 125000000 * 10 ** 18;  
    uint256 public constant founderAllocation = 37500000 * 10 ** 18;  
    uint256 public constant advisorAllocation = 25000000 * 10 ** 18;  
    uint256 public constant reservedAllocation = 62500000 * 10 ** 18;  
    uint256 public constant minInvestedCap = 6000 * 10 ** 18;  
    uint256 public constant minInvestedAmount = 0.1 * 10 ** 18;  
    
    uint saleState;
    uint256 totalInvestedAmount;
    uint public icoStartTime;
    uint public icoEndTime;
    bool public inActive;
    bool public isSelling;
    bool public isTransferable;
    uint public founderAllocatedTime = 1;
    uint public advisorAllocatedTime = 1;
    
    uint256 public totalRemainingTokensForSales;  
    uint256 public totalAdvisor;  
    uint256 public totalReservedTokenAllocation;  

    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);  

    event StartICO(uint state);  
    event EndICO(uint state);  
    
    
    event AllocateTokensForFounder(address founderAddress, uint256 founderAllocatedTime, uint256 tokenAmount);  
    event AllocateTokensForAdvisor(address advisorAddress, uint256 advisorAllocatedTime, uint256 tokenAmount);  
    event AllocateReservedTokens(address reservedAddress, uint256 tokenAmount);  
    event AllocateSalesTokens(address salesAllocation, uint256 tokenAmount);  


    modifier isActive() {
        require(inActive == false);
        _;
    }

    modifier isInSale() {
        require(isSelling == true);
        _;
    }

    modifier transferable() {
        require(isTransferable == true);
        _;
    }

    modifier onlyOwnerOrAdminOrPortal() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    function Extradecoin(address _walletAddr, address _adminAddr) public Owner(msg.sender) {
        require(_walletAddr != address(0));
        require(_adminAddr != address(0));
		
        walletAddress = _walletAddr;
        adminAddress = _adminAddr;
        inActive = true;
        totalInvestedAmount = 0;
        totalRemainingTokensForSales = salesAllocation;
        totalAdvisor = advisorAllocation;
        totalReservedTokenAllocation = reservedAllocation;
    }

     
    function transfer(address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) external transferable returns (bool) {
        require(_spender != address(0));
        require(_value > 0);
		
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function startICO() external isActive onlyOwnerOrAdmin returns (bool) {
        saleState = IN_ICO;
        icoStartTime = now;
        isSelling = true;
        emit StartICO(saleState);
        return true;
    }

     
    function endICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(icoEndTime == 0);
        saleState = END_SALE;
        isSelling = false;
        icoEndTime = now;
        emit EndICO(saleState);
        return true;
    }

     
    function activate() external onlyOwner {
        inActive = false;
    }

     
    function deActivate() external onlyOwner {
        inActive = true;
    }

     
    function enableTokenTransfer() external isActive onlyOwner {
        isTransferable = true;
    }

     
    function changeWallet(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(walletAddress != _newAddress);
        walletAddress = _newAddress;
    }

     
    function changeAdminAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(adminAddress != _newAddress);
        adminAddress = _newAddress;
    }
  
     
    function changeFounderAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(founderAddress != _newAddress);
        founderAddress = _newAddress;
    }

     
    function changeTeamAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(advisorAddress != _newAddress);
        advisorAddress = _newAddress;
    }

     
    function allocateTokensForFounder() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(founderAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            require(now >= icoEndTime + lockPeriod1);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (founderAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod2);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 3;
            return;
        }
        revert();
    }
    

     
    function allocateTokensForAdvisor() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(advisorAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            amount = advisorAllocation * 50/100;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForFounder(advisorAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (advisorAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod2);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 3;
            return;
        }
        if (advisorAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 4;
            return;
        }
        if (advisorAllocatedTime == 4) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 5;
            return;
        }
        if (advisorAllocatedTime == 5) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 6;
            return;
        }
        revert();
    }
    
     
    function allocateReservedTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalReservedTokenAllocation = totalReservedTokenAllocation.sub(_amount);
        emit AllocateReservedTokens(_addr, _amount);
    }

    
    function allocateSalesTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalRemainingTokensForSales = totalRemainingTokensForSales.sub(_amount);
        emit AllocateSalesTokens(_addr, _amount);
    }
     
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function isSoftCapReached() public view returns (bool) {
        return totalInvestedAmount >= minInvestedCap;
    }
}