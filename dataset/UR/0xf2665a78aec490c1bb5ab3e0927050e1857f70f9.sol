 

 
  
  pragma solidity 0.4.23;
  library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ChefICO {
    
    using SafeMath for uint256;
    
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalAmount;
    uint256 public chefPrice;
    uint256 public minimumInvestment;
    uint256 public maximumInvestment;
    uint256 public finalBonus;
    
    uint256 public icoStart;
    uint256 public icoEnd;
    address public chefOwner;

    bool public softCapReached = false;
    bool public hardCapReached = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public chefBalanceOf;

    event ChefICOSucceed(address indexed recipient, uint totalAmount);
    event ChefICOTransfer(address indexed tokenHolder, uint value, bool isContribution);


    function ChefICO() public {
        softCap = 7000 * 1 ether;
        hardCap = 22500 * 1 ether;
        totalAmount = 1100 * 1 ether;  
        chefPrice = 0.0001 * 1 ether;
        minimumInvestment = 1 ether / 5;
        maximumInvestment = 250 * 1 ether;
       
        icoStart = 1525471200;
        icoEnd = 1530396000;
        chefOwner = msg.sender;
    }
    
    
    function balanceOf(address _contributor) public view returns (uint256 balance) {
        return balanceOf[_contributor];
    }
    
    
    function chefBalanceOf(address _contributor) public view returns (uint256 balance) {
        return chefBalanceOf[_contributor];
    }


    modifier onlyOwner() {
        require(msg.sender == chefOwner);
        _;
    }
    
    
    modifier afterICOdeadline() { 
        require(now >= icoEnd );
            _; 
        }
        
        
    modifier beforeICOdeadline() { 
        require(now <= icoEnd );
            _; 
        }
    
   
    function () public payable beforeICOdeadline {
        uint256 amount = msg.value;
        require(!hardCapReached);
        require(amount >= minimumInvestment && balanceOf[msg.sender] < maximumInvestment);
        
        if(hardCap <= totalAmount.add(amount)) {
            hardCapReached = true;
            emit ChefICOSucceed(chefOwner, hardCap);
            
             if(hardCap < totalAmount.add(amount)) {
                uint256 returnAmount = totalAmount.add(amount).sub(hardCap);
                msg.sender.transfer(returnAmount);
                emit ChefICOTransfer(msg.sender, returnAmount, false);
                amount = amount.sub(returnAmount);    
             }
        }
        
        if(maximumInvestment < balanceOf[msg.sender].add(amount)) {
          uint overMaxAmount = balanceOf[msg.sender].add(amount).sub(maximumInvestment);
          msg.sender.transfer(overMaxAmount);
          emit ChefICOTransfer(msg.sender, overMaxAmount, false);
          amount = amount.sub(overMaxAmount);
        }

        totalAmount = totalAmount.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
               
        if (amount >= 10 ether) {
            if (amount >= 150 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(135).div(100));
            }
            else if (amount >= 70 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(130).div(100));
            }
            else if (amount >= 25 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(125).div(100));
            }
            else {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(120).div(100));
            }
        }
        else if (now <= icoStart.add(10 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(120).div(100));
        }
        else if (now <= icoStart.add(20 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(115).div(100));
        }
        else if (now <= icoStart.add(30 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(110).div(100));
        }
        else if (now <= icoStart.add(40 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(105).div(100));
        }
        else {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice));
        }
        
        emit ChefICOTransfer(msg.sender, amount, true);
        
        if (totalAmount >= softCap && softCapReached == false ){
        softCapReached = true;
        emit ChefICOSucceed(chefOwner, totalAmount);
        }
    }

    
   function safeWithdrawal() public afterICOdeadline {
        if (!softCapReached) {
	    uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit ChefICOTransfer(msg.sender, amount, false);
            }
        }
    }
        
    
    function chefOwnerWithdrawal() public onlyOwner {    
        if ((now >= icoEnd && softCapReached) || hardCapReached) {
            chefOwner.transfer(totalAmount);
            emit ChefICOTransfer(chefOwner, totalAmount, false);
        }
    }
}