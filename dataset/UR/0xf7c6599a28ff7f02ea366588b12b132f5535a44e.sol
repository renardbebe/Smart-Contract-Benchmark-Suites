 

pragma solidity ^0.5.1;

 
interface CompoundContract {
    function  supply (address asset, uint256 amount) external returns (uint256);
    function withdraw (address asset, uint256 requestedAmount) external returns (uint256);
}

 
interface token {
    function transfer(address _to, uint256 _value) external returns (bool success) ;
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
}

 
 contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }

 
contract CompoundPayroll is owned {
     
    address compoundAddress = 0x3FDA67f7583380E67ef93072294a7fAc882FD7E7;
    address daiAddress = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    CompoundContract compound = CompoundContract(compoundAddress);
    token dai = token(daiAddress);
    
     
    Salary[] public payroll;
    mapping (address => uint) public salaryId;
    uint public payrollLength;
    
    struct Salary {
        address recipient;
        uint payRate;
        uint lastPaid;
        string name;
    }
    
     
    event MemberPaid(address recipient, uint amount, string justification);

     
    constructor() public {
        owner = msg.sender;
        dai.approve(compoundAddress, 2 ** 128);
        changePay(address(0), 0, now, '');
    }
    
     
    function putInSavings() public  {
        compound.supply(daiAddress, dai.balanceOf(address(this)));
    }
    
     
    function cashOut (uint256 amount, address recipient, string memory justification) public onlyOwner {
        compound.withdraw(daiAddress, amount);
        dai.transfer(recipient, amount);
        emit MemberPaid( recipient,  amount, justification);

    }

     
    function changePay(address recipient, uint yearlyPay, uint startingDate, string memory initials) onlyOwner public {
         
        uint id = salaryId[recipient];
         
        if (id == 0) {
            salaryId[recipient] = payroll.length;
            id = payroll.length++;
        }
        payroll[id] = Salary({
            recipient: recipient, 
            payRate: yearlyPay / 365.25 days, 
            lastPaid:  startingDate >  0 ? startingDate : now, 
            name: initials});
            
        payrollLength = payroll.length;
    }

     
    function removePay(address recipient) onlyOwner public {
        require(salaryId[recipient] != 0);

        for (uint i = salaryId[recipient]; i<payroll.length-1; i++){
            payroll[i] = payroll[i+1];
            salaryId[payroll[i].recipient] = i;
        }
        
        salaryId[recipient] = 0;
        delete payroll[payroll.length-1];
        payroll.length--;
        payrollLength = payroll.length;
    }
    
     
    function getAmountOwed(address recipient) view public returns (uint256) {
         
        uint id = salaryId[recipient];
        if (id > 0) {
             
            return (now - payroll[id].lastPaid) * payroll[id].payRate;
        } else {
            return 0;
        }
    }
    
     
    function paySalary(address recipient, string memory justification) public {
         
        uint amount = getAmountOwed(recipient);
        if (amount == 0) return;
        
         
        compound.withdraw(daiAddress, amount);
        
         
        payroll[salaryId[recipient]].lastPaid = now;
        dai.transfer(recipient, amount);
        emit MemberPaid( recipient,  amount, justification);
    }
    
     
    function payAll() public {
        for (uint i = 1; i<payroll.length-1; i++){
            paySalary(payroll[i].recipient, 'payAll');
        }
    }
    
     
    function () external payable {
        putInSavings();
        payAll();
        msg.sender.transfer(msg.value);
    }
    
     
     
     
     
     
     
       
     
     
     
     
     
        
     
        
     
        
     
     
     
     
     
                
     
     
     
}