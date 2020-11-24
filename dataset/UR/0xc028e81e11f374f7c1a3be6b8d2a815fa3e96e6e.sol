 

pragma solidity ^0.5.10;

 
contract NEST_NodeSave {
    IBMapping mappingContract;                      
    IBNEST nestContract;                             
    
     
    constructor (address map) public {
        mappingContract = IBMapping(address(map));              
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));            
    }
    
     
    function changeMapping(address map) public onlyOwner {
        mappingContract = IBMapping(address(map));              
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));            
    }
    
     
    function turnOut(uint256 amount, address to) public onlyMiningCalculation returns(uint256) {
        uint256 leftNum = nestContract.balanceOf(address(this));
        if (leftNum >= amount) {
            nestContract.transfer(to, amount);
            return amount;
        } else {
            return 0;
        }
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }

    modifier onlyMiningCalculation(){
        require(address(mappingContract.checkAddress("nodeAssignment")) == msg.sender);
        _;
    }
    
}

 
contract NEST_NodeAssignmentData {
    using SafeMath for uint256;
    IBMapping mappingContract;              
    uint256 nodeAllAmount = 0;                                 
    mapping(address => uint256) nodeLatestAmount;               
    
     
    constructor (address map) public {
        mappingContract = IBMapping(map); 
    }
    
     
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
    }
    
     
    function addNest(uint256 amount) public onlyNodeAssignment {
        nodeAllAmount = nodeAllAmount.add(amount);
    }
    
     
    function checkNodeAllAmount() public view returns (uint256) {
        return nodeAllAmount;
    }
    
     
    function addNodeLatestAmount(address add ,uint256 amount) public onlyNodeAssignment {
        nodeLatestAmount[add] = amount;
    }
    
     
    function checkNodeLatestAmount(address add) public view returns (uint256) {
        return nodeLatestAmount[address(add)];
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
    
    modifier onlyNodeAssignment(){
        require(address(msg.sender) == address(mappingContract.checkAddress("nodeAssignment")));
        _;
    }
}

 
contract NEST_NodeAssignment {
    
    using SafeMath for uint256;
    IBMapping mappingContract;  
    IBNEST nestContract;                                   
    SuperMan supermanContract;                              
    NEST_NodeSave nodeSave;
    NEST_NodeAssignmentData nodeAssignmentData;

     
    constructor (address map) public {
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.checkAddress("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
     
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.checkAddress("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
     
    function bookKeeping(uint256 amount) public {
        require(amount > 0);
        require(nestContract.balanceOf(address(msg.sender)) >= amount);
        require(nestContract.allowance(address(msg.sender), address(this)) >= amount);
        require(nestContract.transferFrom(address(msg.sender), address(nodeSave), amount));
        nodeAssignmentData.addNest(amount);
    }
    
     
    function nodeGet() public {
        require(address(msg.sender) == address(tx.origin));
        require(supermanContract.balanceOf(address(msg.sender)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
        uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
        require(nestContract.balanceOf(address(nodeSave)) >= getAmount);
        nodeSave.turnOut(getAmount,address(msg.sender));
        nodeAssignmentData.addNodeLatestAmount(address(msg.sender),allAmount);
    }
    
     
    function nodeCount(address fromAdd, address toAdd) public {
        require(address(supermanContract) == address(msg.sender));
        require(supermanContract.balanceOf(address(fromAdd)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        
        uint256 amountFrom = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(fromAdd)));
        uint256 getAmountFrom = amountFrom.mul(supermanContract.balanceOf(address(fromAdd))).div(1500);
        require(nestContract.balanceOf(address(nodeSave)) >= getAmountFrom);
        nodeSave.turnOut(getAmountFrom,address(fromAdd));
        nodeAssignmentData.addNodeLatestAmount(address(fromAdd),allAmount);
        
        uint256 amountTo = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(toAdd)));
        uint256 getAmountTo = amountTo.mul(supermanContract.balanceOf(address(toAdd))).div(1500);
        require(nestContract.balanceOf(address(nodeSave)) >= getAmountTo);
        nodeSave.turnOut(getAmountTo,address(toAdd));
        nodeAssignmentData.addNodeLatestAmount(address(toAdd),allAmount);
    }
    
     
    function checkNodeNum() public view returns (uint256) {
         uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
         uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
         uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
         return getAmount;
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}


 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

 
contract SuperMan is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    IBMapping mappingContract;   

    uint256 private _totalSupply = 1500;
    string public name = "NestNode";
    string public symbol = "NN";
    uint8 public decimals = 0;

    constructor (address map) public {
    	_balances[msg.sender] = _totalSupply;
    	mappingContract = IBMapping(map); 
    }
    
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map);
    }
    
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        
        NEST_NodeAssignment nodeAssignment = NEST_NodeAssignment(address(mappingContract.checkAddress("nodeAssignment")));
        nodeAssignment.nodeCount(from, to);
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        
        
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
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

contract IBMapping {
	function checkAddress(string memory name) public view returns (address contractAddress);
	function checkOwners(address man) public view returns (bool);
}

contract IBNEST {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
    
    function balancesStart() public view returns(uint256);
    function balancesGetBool(uint256 num) public view returns(bool);
    function balancesGetNext(uint256 num) public view returns(uint256);
    function balancesGetValue(uint256 num) public view returns(address, uint256);
}