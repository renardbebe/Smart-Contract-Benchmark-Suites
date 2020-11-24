 

pragma solidity 0.5.1;

library ECTools {

   
    function recover(bytes32 originalMessage, bytes memory signedMessage) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signedMessage.length != 65) {
            return (address(0));
        }

         
        assembly {
            r := mload(add(signedMessage, 32))
            s := mload(add(signedMessage, 64))
            v := byte(0, mload(add(signedMessage, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(originalMessage, v, r, s);
        }
    }

    function toEthereumSignedMessage(bytes32 _msg) public pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, _msg));
    }

    function prefixedRecover(bytes32 _msg, bytes memory sig) public pure returns (address) {
        bytes32 ethSignedMsg = toEthereumSignedMessage(_msg);
        return recover(ethSignedMsg, sig);
    }
}

 
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


 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
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

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}




 
contract Escrow_V3 {
    using SafeMath for uint256;

    ERC20 public tokenContract;

    mapping (address => bool) public signers;
    mapping (address => bool) public fundExecutors;
    mapping (uint256 => bool) public usedNonces;

    address payable public dAppAdmin;
    uint256 constant public REFUNDING_LOGIC_GAS_COST = 7901;  

    uint256 constant public FIAT_PAYMENT_FUND_FUNCTION_CALL_GAS_USED = 32831;  
    uint256 constant public RELAYED_PAYMENT_FUND_FUNCTION_CALL_GAS_USED = 32323;  

     
    modifier onlyDAppAdmin() {
        require(msg.sender == dAppAdmin, "Unauthorized access");
        _;
    }

     
    modifier onlyFundExecutor() {
        require(fundExecutors[msg.sender], "Unauthorized access");
        _;
    }

     
    modifier preValidateFund(uint256 nonce, uint256 gasprice) {
        require(!usedNonces[nonce], "Nonce already used");
        require(gasprice == tx.gasprice, "Gas price is different from the signed one");
        _;
    }

     
    constructor(address tokenAddress, address payable _dAppAdmin, address[] memory _fundExecutors) public {
        dAppAdmin = _dAppAdmin;
        tokenContract = ERC20(tokenAddress);
        for (uint i = 0; i < _fundExecutors.length; i++) {
            fundExecutors[_fundExecutors[i]] = true;
        }
    }
   
     
    function fundForRelayedPayment(
        uint256 nonce,
        uint256 gasprice,
        address payable addressToFund,
        uint256 weiAmount,
        bytes memory authorizationSignature) public preValidateFund(nonce, gasprice) onlyFundExecutor()
    {
        uint256 gasLimit = gasleft().add(RELAYED_PAYMENT_FUND_FUNCTION_CALL_GAS_USED);

        bytes32 hashedParameters = keccak256(abi.encodePacked(nonce, address(this), gasprice, addressToFund, weiAmount));
        _preFund(hashedParameters, authorizationSignature, nonce);

        addressToFund.transfer(weiAmount);

        _refundMsgSender(gasLimit, gasprice);
    }

     
    function fundForFiatPayment(
        uint256 nonce,
        uint256 gasprice,
        address payable addressToFund,
        uint256 weiAmount,
        uint256 tokenAmount,
        bytes memory authorizationSignature) public preValidateFund(nonce, gasprice) onlyFundExecutor()
    {
        uint256 gasLimit = gasleft().add(FIAT_PAYMENT_FUND_FUNCTION_CALL_GAS_USED);

        bytes32 hashedParameters = keccak256(abi.encodePacked(nonce, address(this), gasprice, addressToFund, weiAmount, tokenAmount));
        _preFund(hashedParameters, authorizationSignature, nonce);

        tokenContract.transfer(addressToFund, tokenAmount);
        addressToFund.transfer(weiAmount);

        _refundMsgSender(gasLimit, gasprice);
    }

     
    function _preFund(bytes32 hashedParameters, bytes memory authorizationSignature, uint256 nonce) internal {
        address signer = getSigner(hashedParameters, authorizationSignature);
        require(signers[signer], "Invalid authorization signature or signer");

        usedNonces[nonce] = true;
    }

     
    function getSigner(bytes32 raw, bytes memory sig) public pure returns(address signer) {
        return ECTools.prefixedRecover(raw, sig);
    }

     
    function _refundMsgSender(uint256 gasLimit, uint256 gasprice) internal {
        uint256 refundAmount = gasLimit.sub(gasleft()).add(REFUNDING_LOGIC_GAS_COST).mul(gasprice);
        msg.sender.transfer(refundAmount);
    }

     
    function withdrawEthers(uint256 ethersAmount) public onlyDAppAdmin {
        dAppAdmin.transfer(ethersAmount);
    }

     
    function withdrawTokens(uint256 tokensAmount) public onlyDAppAdmin {
        tokenContract.transfer(dAppAdmin, tokensAmount);
    }

     
    function editSigner(address _newSigner, bool add) public onlyDAppAdmin {
        signers[_newSigner] = add;
    }

     
    function editDappAdmin (address payable _dAppAdmin) public onlyDAppAdmin {
        dAppAdmin = _dAppAdmin;
    }

     
    function editFundExecutor(address _newExecutor, bool add) public onlyDAppAdmin {
        fundExecutors[_newExecutor] = add;
    }

    function() external payable {}
}