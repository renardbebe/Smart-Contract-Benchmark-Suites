 

 

pragma solidity ^0.5.7;

contract IRC20Vanilla {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Vanilla is IRC20Vanilla {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    constructor(address _manager, uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol
    ) public {
        balances[_manager] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

contract CampaignMango {

    using SafeMath for uint256;
    
     
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests;  
    address public manager;  
    uint256 minimumContribution;  

     
    uint8 approversFactor;
    
    mapping(address => bool) public approvers;
    uint256 public approversCount;

     
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

     
    constructor(address creator, uint256 minimum, uint8 factor) public {
         
        require(factor >= 2);
        require(factor <= 10);
        manager = creator;
        approversFactor = factor;
        minimumContribution = minimum;
    }
    
     
    function contribute() public payable {
         
        require(msg.value >= minimumContribution);

         
        if (!approvers[msg.sender]) {
            approversCount++;
        }

        approvers[msg.sender] = true;  

    }

     
    function createRequest(string memory description, uint256 value, address payable recipient) public restricted {

         
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });

        requests.push(newRequest);

    }

     
    function approveRequest(uint256 index) public {
        
         
        Request storage request = requests[index];
        
         
        require(approvers[msg.sender]);
        
         
        require(!request.approvals[msg.sender]);
        
         
        request.approvals[msg.sender] = true;
        
         
        request.approvalCount++;
        
    }

     
    function approved(uint256 index) public view returns (bool) {

         
        if (approvers[msg.sender] && requests[index].approvals[msg.sender]) {
            return true;
        } else {
            return false;
        }

    }
    
     
     
    function finalizeRequest(uint256 index) public restricted {
        
         
        Request storage request = requests[index];

         
        require(request.approvalCount >= approversCount.div(approversFactor));
        
         
        require(!request.complete);
        
         
        request.complete = true;
        
         
        request.recipient.transfer(request.value);
        
    }

     
    function getSummary() public view returns (
      uint256, uint256, uint256, uint256, address
      ) {
        return (
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }

}