 

 
 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;


contract Token {
    using SafeMath for uint;

     
    string public name = "Yasuda Takahashi coin";
    string public symbol = "YATA";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
         
        totalSupply = 1000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
}

 

pragma solidity ^0.5.0;



contract Exchange {
    using SafeMath for uint;

     
    address constant ETHER = address(0);  
    mapping(address => mapping(address => uint256)) public tokens;  
    mapping(uint256 => _Order) public orders;
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    address public owner;  
    address internal ercToken;
    mapping(address => _Fee[]) public feeDistributions;    
    _Fee[] public feeDetails;


     
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Order(
        uint256 id,
        address user,
        address ercToken,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Cancel(
        uint256 id,
        address user,
        address ercToken,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Trade(
        uint256 id,
        address user,
        address ercToken,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    struct _Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    struct _Fee {
        uint256 id;
        string name;
        address wallet;
        uint256 percent;
        bool active;
    }

    constructor () public {
        owner = msg.sender;
    }    

     
    function() external {
        revert();
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    function depositEther() payable public {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    function withdrawEther(uint _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    function depositToken(address _token, uint _amount) public {
        require(_token != ETHER);
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        require(tokens[_token][msg.sender] >= _amount);
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }

    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);

        ercToken = _getErcTokenAddress(_tokenGet, _tokenGive);

        emit Order(orderCount, msg.sender, ercToken, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    }

    function cancelOrder(uint256 _id) public {
        _Order storage _order = orders[_id];
        require(address(_order.user) == msg.sender);
        require(_order.id == _id);  
        orderCancelled[_id] = true;

        ercToken = _getErcTokenAddress(_order.tokenGet, _order.tokenGive);

        emit Cancel(_order.id, msg.sender, ercToken, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    }

    function fillOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount);
        require(!orderFilled[_id]);
        require(!orderCancelled[_id]);
        _Order storage _order = orders[_id];
        _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
        orderFilled[_order.id] = true;
    }

    function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
        ercToken = _getErcTokenAddress(_tokenGet, _tokenGive);
        uint totalFeePercent = getTotalFeePercent (ercToken);

        uint256 _feeAmount = _amountGet.mul(totalFeePercent).div(100000);   

        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);       

         
        uint256 feesCount = getFeeDistributionsCount(ercToken);
        _Fee[] storage fees = feeDistributions[ercToken];

        for (uint i = 0; i < feesCount; i++){
            if (fees[i].active){
                uint feeValue = _amountGet.mul(fees[i].percent).div(100000);   
                tokens[_tokenGet][fees[i].wallet] = tokens[_tokenGet][fees[i].wallet].add(feeValue);
            }
        }


        emit Trade(_orderId, _user, ercToken, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "address not valid");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }


    function _getErcTokenAddress(address tokenGet, address tokenGive) internal returns (address){
        if (tokenGet == ETHER){
            ercToken = tokenGive;
        } else {
            ercToken = tokenGet;
        }
        return ercToken;
    }

    function getFeeDistributionsCount(address _token) public view returns(uint) {
        _Fee[] storage fees = feeDistributions[_token];
        return fees.length;
    }

    function getTotalFeePercent (address _ercToken) public view returns (uint){
        require(_ercToken != address(0), "address not valid");
        uint256 totalFeePercent = 0;
        uint256 feesCount = getFeeDistributionsCount(_ercToken);
        _Fee[] storage fees = feeDistributions[_ercToken];

        for (uint i = 0; i < feesCount; i++){
            if (fees[i].active){
                totalFeePercent = totalFeePercent.add(fees[i].percent);
            }
        }

        return totalFeePercent;
    }

     
    function setFeeDistributions(address _token, address _feeWallet, string memory _name, uint256 _percent) public  onlyOwner {
        require(_token != address(0), "address not valid");
        require(_feeWallet != address(0), "address not valid");

        _Fee[] storage fees = feeDistributions[_token];
         
        uint256 feesCount = getFeeDistributionsCount(_token);

        bool feeExiste = false;

        uint totalFeePercent = getTotalFeePercent (_token);
        totalFeePercent = totalFeePercent.add(_percent);
        require(totalFeePercent <= 100000, "total fee cannot exceed 100");

        for (uint i = 0; i < feesCount; i++){
            if (fees[i].wallet == _feeWallet){
                fees[i].name    = _name;
                fees[i].percent = _percent;
                fees[i].active  = true;

                feeExiste = true;
                break;
            }
        }

         
        if (!feeExiste){
            _Fee memory fee;

            fee.id = (feesCount + 1);
            fee.name = _name;
            fee.wallet = _feeWallet;
            fee.percent = _percent;
            fee.active = true;

            fees.push(fee);
        }
    }

    function deActivateFeeWallet(address _token, address _feeWallet) public onlyOwner {
        require(_token != address(0), "address not valid");
        require(_feeWallet != address(0), "address not valid");

        _Fee[] storage fees = feeDistributions[_token];
        uint256 feesCount = getFeeDistributionsCount(_token);
        for (uint i = 0; i < feesCount; i++){
            if (fees[i].wallet == _feeWallet){
                fees[i].active = false;
                break;
            }
        }
    }

}