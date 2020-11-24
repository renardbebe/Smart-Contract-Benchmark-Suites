 

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


contract GreenX is Owner {
    using SafeMath for uint256;

    string public constant name = "GREENX";
    string public constant symbol = "GEX";
    uint public constant decimals = 18;
    uint256 constant public totalSupply = 375000000 * 10 ** 18;  
  
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    address public portalAddress;
    address public adminAddress;
    address public walletAddress;
    address public founderAddress;
    address public teamAddress;

    mapping(address => bool) public privateList;
    mapping(address => bool) public whiteList;
    mapping(address => uint256) public totalInvestedAmountOf;

    uint constant lockPeriod1 = 180 days;  
    uint constant lockPeriod2 = 1 years;  
    uint constant lockPeriod3 = 2 years;  
    uint constant NOT_SALE = 0;  
    uint constant IN_PRIVATE_SALE = 1;  
    uint constant IN_PRESALE = 2;  
    uint constant END_PRESALE = 3;  
    uint constant IN_1ST_ICO = 4;  
    uint constant IN_2ND_ICO = 5;  
    uint constant IN_3RD_ICO = 6;  
    uint constant END_SALE = 7;  

    uint256 public constant salesAllocation = 187500000 * 10 ** 18;  
    uint256 public constant bonusAllocation = 37500000 * 10 ** 18;  
    uint256 public constant reservedAllocation = 90000000 * 10 ** 18;  
    uint256 public constant founderAllocation = 37500000 * 10 ** 18;  
    uint256 public constant teamAllocation = 22500000 * 10 ** 18;  
    uint256 public constant minInvestedCap = 2500 * 10 ** 18;  
    uint256 public constant minInvestedAmount = 0.1 * 10 ** 18;  
    
    uint saleState;
    uint256 totalInvestedAmount;
    uint public icoStartTime;
    uint public icoEndTime;
    bool public inActive;
    bool public isSelling;
    bool public isTransferable;
    uint public founderAllocatedTime = 1;
    uint public teamAllocatedTime = 1;
    uint256 public privateSalePrice;
    uint256 public preSalePrice;
    uint256 public icoStandardPrice;
    uint256 public ico1stPrice;
    uint256 public ico2ndPrice;
    uint256 public totalRemainingTokensForSales;  
    uint256 public totalReservedAndBonusTokenAllocation;  
    uint256 public totalLoadedRefund;  
    uint256 public totalRefundedAmount;  

    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);  

    event ModifyWhiteList(address investorAddress, bool isWhiteListed);   
    event ModifyPrivateList(address investorAddress, bool isPrivateListed);   
    event StartPrivateSales(uint state);  
    event StartPresales(uint state);  
    event EndPresales(uint state);  
    event StartICO(uint state);  
    event EndICO(uint state);  
    
    event SetPrivateSalePrice(uint256 price);  
    event SetPreSalePrice(uint256 price);  
    event SetICOPrice(uint256 price);  
    
    event IssueTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint state);  
    event RevokeTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint256 txFee);  
    event AllocateTokensForFounder(address founderAddress, uint256 founderAllocatedTime, uint256 tokenAmount);  
    event AllocateTokensForTeam(address teamAddress, uint256 teamAllocatedTime, uint256 tokenAmount);  
    event AllocateReservedTokens(address reservedAddress, uint256 tokenAmount);  
    event Refund(address investorAddress, uint256 etherRefundedAmount, uint256 tokensRevokedAmount);  

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
        require(msg.sender == owner || msg.sender == adminAddress || msg.sender == portalAddress);
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    function GreenX(address _walletAddr, address _adminAddr, address _portalAddr) public Owner(msg.sender) {
        require(_walletAddr != address(0));
        require(_adminAddr != address(0));
        require(_portalAddr != address(0));
		
        walletAddress = _walletAddr;
        adminAddress = _adminAddr;
        portalAddress = _portalAddr;
        inActive = true;
        totalInvestedAmount = 0;
        totalRemainingTokensForSales = salesAllocation;
        totalReservedAndBonusTokenAllocation = reservedAllocation + bonusAllocation;
    }

     
    function () external payable isActive isInSale {
        uint state = getCurrentState();
        require(state >= IN_PRIVATE_SALE && state < END_SALE);
        require(msg.value >= minInvestedAmount);

        bool isPrivate = privateList[msg.sender];
        if (isPrivate == true) {
            return issueTokensForPrivateInvestor(state);
        }
        if (state == IN_PRESALE) {
            return issueTokensForPresale(state);
        }
        if (IN_1ST_ICO <= state && state <= IN_3RD_ICO) {
            return issueTokensForICO(state);
        }
        revert();
    }

     
    function loadFund() external payable {
        require(msg.value > 0);
		
        totalLoadedRefund = totalLoadedRefund.add(msg.value);
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

     
    function modifyWhiteList(address[] _investorAddrs, bool _isWhiteListed) external isActive onlyOwnerOrAdminOrPortal returns(bool) {
        for (uint256 i = 0; i < _investorAddrs.length; i++) {
            whiteList[_investorAddrs[i]] = _isWhiteListed;
            emit ModifyWhiteList(_investorAddrs[i], _isWhiteListed);
        }
        return true;
    }

     
    function modifyPrivateList(address[] _investorAddrs, bool _isPrivateListed) external isActive onlyOwnerOrAdminOrPortal returns(bool) {
        for (uint256 i = 0; i < _investorAddrs.length; i++) {
            privateList[_investorAddrs[i]] = _isPrivateListed;
            emit ModifyPrivateList(_investorAddrs[i], _isPrivateListed);
        }
        return true;
    }

     
    function startPrivateSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == NOT_SALE);
        require(privateSalePrice > 0);
		
        saleState = IN_PRIVATE_SALE;
        isSelling = true;
        emit StartPrivateSales(saleState);
        return true;
    }

     
    function startPreSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState < IN_PRESALE);
        require(preSalePrice > 0);
		
        saleState = IN_PRESALE;
        isSelling = true;
        emit StartPresales(saleState);
        return true;
    }

     
    function endPreSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == IN_PRESALE);
		
        saleState = END_PRESALE;
        isSelling = false;
        emit EndPresales(saleState);
        return true;
    }

     
    function startICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == END_PRESALE);
        require(icoStandardPrice > 0);
		
        saleState = IN_1ST_ICO;
        icoStartTime = now;
        isSelling = true;
        emit StartICO(saleState);
        return true;
    }

     
    function endICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(getCurrentState() == IN_3RD_ICO);
        require(icoEndTime == 0);
		
        saleState = END_SALE;
        isSelling = false;
        icoEndTime = now;
        emit EndICO(saleState);
        return true;
    }

     
    function setPrivateSalePrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        privateSalePrice = _tokenPerEther;
        emit SetPrivateSalePrice(privateSalePrice);
        return true;
    }

     
    function setPreSalePrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        preSalePrice = _tokenPerEther;
        emit SetPreSalePrice(preSalePrice);
        return true;
    }

     
    function setICOPrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        icoStandardPrice = _tokenPerEther;
        ico1stPrice = _tokenPerEther + _tokenPerEther * 20 / 100;
        ico2ndPrice = _tokenPerEther + _tokenPerEther * 10 / 100;
        emit SetICOPrice(icoStandardPrice);
        return true;
    }

     
    function revokeTokens(address _noneKycAddr, uint256 _transactionFee) external onlyOwnerOrAdmin {
        require(_noneKycAddr != address(0));
        uint256 investedAmount = totalInvestedAmountOf[_noneKycAddr];
        uint256 totalRemainingRefund = totalLoadedRefund.sub(totalRefundedAmount);
        require(whiteList[_noneKycAddr] == false && privateList[_noneKycAddr] == false);
        require(investedAmount > 0);
        require(totalRemainingRefund >= investedAmount);
        require(saleState == END_SALE);
		
        uint256 refundAmount = investedAmount.sub(_transactionFee);
        uint tokenRevoked = balances[_noneKycAddr];
        totalInvestedAmountOf[_noneKycAddr] = 0;
        balances[_noneKycAddr] = 0;
        totalRemainingTokensForSales = totalRemainingTokensForSales.add(tokenRevoked);
        totalRefundedAmount = totalRefundedAmount.add(refundAmount);
        _noneKycAddr.transfer(refundAmount);
        emit RevokeTokens(_noneKycAddr, refundAmount, tokenRevoked, _transactionFee);
    }    

     
    function refund() external {
        uint256 refundedAmount = totalInvestedAmountOf[msg.sender];
        uint256 totalRemainingRefund = totalLoadedRefund.sub(totalRefundedAmount);
        uint256 tokenRevoked = balances[msg.sender];
        require(saleState == END_SALE);
        require(!isSoftCapReached());
        require(totalRemainingRefund >= refundedAmount && refundedAmount > 0);
		
        totalInvestedAmountOf[msg.sender] = 0;
        balances[msg.sender] = 0;
        totalRemainingTokensForSales = totalRemainingTokensForSales.add(tokenRevoked);
        totalRefundedAmount = totalRefundedAmount.add(refundedAmount);
        msg.sender.transfer(refundedAmount);
        emit Refund(msg.sender, refundedAmount, tokenRevoked);
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

     
    function changePortalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(portalAddress != _newAddress);
        portalAddress = _newAddress;
    }
  
     
    function changeFounderAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(founderAddress != _newAddress);
        founderAddress = _newAddress;
    }

     
    function changeTeamAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(teamAddress != _newAddress);
        teamAddress = _newAddress;
    }

     
    function allocateTokensForFounder() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(founderAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            amount = founderAllocation * 20/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (founderAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod1);
            amount = founderAllocation * 30/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 3;
            return;
        }
        if (founderAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod2);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 4;
            return;
        }
        revert();
    }

     
    function allocateTokensForTeam() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(teamAddress != address(0));
        uint256 amount;
        if (teamAllocatedTime == 1) {
            amount = teamAllocation * 20/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 2;
            return;
        }
        if (teamAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod1);
            amount = teamAllocation * 30/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 3;
            return;
        }
        if (teamAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod2);
            amount = teamAllocation * 50/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 4;
            return;
        }
        revert();
    }

     
    function allocateRemainingTokens(address _addr) external isActive onlyOwnerOrAdmin {
        require(_addr != address(0));
        require(saleState == END_SALE);
        require(totalRemainingTokensForSales > 0);
        require(now >= icoEndTime + lockPeriod3);
        balances[_addr] = balances[_addr].add(totalRemainingTokensForSales);
        totalRemainingTokensForSales = 0;
    }

     
    function allocateReservedTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalReservedAndBonusTokenAllocation = totalReservedAndBonusTokenAllocation.sub(_amount);
        emit AllocateReservedTokens(_addr, _amount);
    }

     
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function getCurrentState() public view returns(uint256) {
        if (saleState == IN_1ST_ICO) {
            if (now > icoStartTime + 30 days) {
                return IN_3RD_ICO;
            }
            if (now > icoStartTime + 15 days) {
                return IN_2ND_ICO;
            }
            return IN_1ST_ICO;
        }
        return saleState;
    }

     
    function isSoftCapReached() public view returns (bool) {
        return totalInvestedAmount >= minInvestedCap;
    }

     
    function issueTokensForPrivateInvestor(uint _state) private {
        uint256 price = privateSalePrice;
        issueTokens(price, _state);
    }

     
    function issueTokensForPresale(uint _state) private {
        uint256 price = preSalePrice;
        issueTokens(price, _state);
    }

     
    function issueTokensForICO(uint _state) private {
        uint256 price = icoStandardPrice;
        if (_state == IN_1ST_ICO) {
            price = ico1stPrice;
        } else if (_state == IN_2ND_ICO) {
            price = ico2ndPrice;
        }
        issueTokens(price, _state);
    }

     
    function issueTokens(uint256 _price, uint _state) private {
        require(walletAddress != address(0));
		
        uint tokenAmount = msg.value.mul(_price).mul(10**18).div(1 ether);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        totalInvestedAmountOf[msg.sender] = totalInvestedAmountOf[msg.sender].add(msg.value);
        totalRemainingTokensForSales = totalRemainingTokensForSales.sub(tokenAmount);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        walletAddress.transfer(msg.value);
        emit IssueTokens(msg.sender, msg.value, tokenAmount, _state);
    }
}