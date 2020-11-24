 

 

pragma solidity ^0.4.24;


 
contract ERC20 {

     
    function totalSupply() public view returns (uint256 supply);

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 


interface IGivethBridge {
    function donate(uint64 giverId, uint64 receiverId) external payable;
    function donate(uint64 giverId, uint64 receiverId, address token, uint _amount) external payable;
}

interface IFundsForwarderFactory {
    function bridge() external returns (address);
    function escapeHatchCaller() external returns (address);
    function escapeHatchDestination() external returns (address);
}

interface IMolochDao {
    function approvedToken() external returns (address);
    function members(address member) external returns (address, uint256, bool, uint256);
    function ragequit(uint sharesToBurn) external;
}

interface IWEth {
    function withdraw(uint wad) external;
    function balanceOf(address guy) external returns (uint);
}


contract FundsForwarder {
    uint64 public receiverId;
    uint64 public giverId;
    IFundsForwarderFactory public fundsForwarderFactory;

    string private constant ERROR_ERC20_APPROVE = "ERROR_ERC20_APPROVE";
    string private constant ERROR_BRIDGE_CALL = "ERROR_BRIDGE_CALL";
    string private constant ERROR_ZERO_BRIDGE = "ERROR_ZERO_BRIDGE";
    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_TOKEN_TRANSFER = "RECOVER_TOKEN_TRANSFER";
    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    uint private constant MAX_UINT = uint(-1);

    event Forwarded(address to, address token, uint balance);
    event EscapeHatchCalled(address token, uint amount);

    constructor() public {
         
         
         
        fundsForwarderFactory = IFundsForwarderFactory(address(-1));
    }

     
    function() public payable {}

     
    function initialize(uint64 _giverId, uint64 _receiverId) public {
         
        require(fundsForwarderFactory == address(0), ERROR_ALREADY_INITIALIZED);
         
        fundsForwarderFactory = IFundsForwarderFactory(msg.sender);
         
        require(fundsForwarderFactory.bridge() != address(0), ERROR_ZERO_BRIDGE);

        receiverId = _receiverId;
        giverId = _giverId;
    }

     
    function forward(address _token) public {
        IGivethBridge bridge = IGivethBridge(fundsForwarderFactory.bridge());
        require(bridge != address(0), ERROR_ZERO_BRIDGE);

        uint balance;
        bool result;
         
        if (_token == address(0)) {
            balance = address(this).balance;
             
             
             
             
            result = address(bridge).call.value(balance)(
                0xbde60ac9,
                giverId,
                receiverId
            );
         
        } else {
            ERC20 token = ERC20(_token);
            balance = token.balanceOf(this);
             
             
             
             
             
             
             
            if (token.allowance(address(this), bridge) < balance) {
                require(token.approve(bridge, MAX_UINT), ERROR_ERC20_APPROVE);
            }

             
             
             
             
            result = address(bridge).call(
                0x4c4316c7,
                giverId,
                receiverId,
                token,
                balance
            );
        }
        require(result, ERROR_BRIDGE_CALL);
        emit Forwarded(bridge, _token, balance);
    }

     
    function forwardMultiple(address[] _tokens) public {
        uint tokensLength = _tokens.length;
        for (uint i = 0; i < tokensLength; i++) {
            forward(_tokens[i]);
        }
    }

     
    function forwardMoloch(address _molochDao, bool _convertWeth) public {
        IMolochDao molochDao = IMolochDao(_molochDao);
        (,uint shares,,) = molochDao.members(address(this));
        molochDao.ragequit(shares);
        address approvedToken = molochDao.approvedToken();
        if (_convertWeth) {
            IWEth weth = IWEth(approvedToken);
            weth.withdraw(weth.balanceOf(address(this)));
            forward(address(0));
        } else {
            forward(molochDao.approvedToken());
        }
    }

     
    function escapeHatch(address _token) public {
         
        require(msg.sender == fundsForwarderFactory.escapeHatchCaller(), ERROR_DISALLOWED);

        address escapeHatchDestination = fundsForwarderFactory.escapeHatchDestination();

        uint256 balance;
        if (_token == 0x0) {
            balance = address(this).balance;
            escapeHatchDestination.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.balanceOf(this);
            require(token.transfer(escapeHatchDestination, balance), ERROR_TOKEN_TRANSFER);
        }

        emit EscapeHatchCalled(_token, balance);
    }
}