 

pragma solidity 0.4.23;
 

 
contract admined {  
    address public admin;  

     
    constructor() internal {
        admin = msg.sender;  
        emit Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20 {
    function name() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract TokenWallet is admined {

     
    constructor() public {    
    }

    event LogTokenAddedToDirectory(uint256 _index, string _name);
    event LogTokenTransfer(address _token, address _to, uint256 _amount);
    event LogTokenAllowanceApprove(address _token, address _to, uint256 _value);

    ERC20[] public tokenDirectory;
    string[] public tokenDirectoryName;

     

    function addTokenToDirectory(ERC20 _tokenContractAddress) onlyAdmin public returns (uint256){
        require(_tokenContractAddress != address(0));
        require(_tokenContractAddress.totalSupply() !=0 );
        uint256 index = tokenDirectory.push(_tokenContractAddress) - 1;
        tokenDirectoryName.push(_tokenContractAddress.name());
        emit LogTokenAddedToDirectory(index,_tokenContractAddress.name());
        return index;

    }
    
    function replaceDirectoryToken(ERC20 _tokenContractAddress, uint256 _directoryIndex) onlyAdmin public returns (uint256){
        require(_tokenContractAddress != address(0));
        require(_tokenContractAddress.totalSupply() !=0 );
        tokenDirectory[_directoryIndex] = _tokenContractAddress;
        tokenDirectoryName[_directoryIndex]= _tokenContractAddress.name();
        emit LogTokenAddedToDirectory(_directoryIndex,_tokenContractAddress.name());
    }

    function balanceOfDirectoryToken(uint256 _index) public view returns (uint256) {
        ERC20 token = tokenDirectory[_index];
        return token.balanceOf(address(this));
    }

    function transferDirectoryToken(uint256 _index, address _to, uint256 _amount) public onlyAdmin{
        ERC20 token = tokenDirectory[_index];
         
        token.transfer(_to,_amount);
        emit LogTokenTransfer(token,_to,_amount);
    }

    function batchTransferDirectoryToken(uint256 _index,address[] _target,uint256[] _amount) onlyAdmin public {
        require(_target.length >= _amount.length);
        uint256 length = _target.length;
        ERC20 token = tokenDirectory[_index];

        for (uint i=0; i<length; i++) {  
            token.transfer(_target[i],_amount[i]);
            emit LogTokenTransfer(token,_target[i],_amount[i]);       
        }
    }

    function giveDirectoryTokenAllowance(uint256 _index, address _spender, uint256 _value) onlyAdmin public{
        ERC20 token = tokenDirectory[_index];
        token.approve(_spender, _value);
        emit LogTokenAllowanceApprove(token,_spender, _value);
    }

     

    function balanceOfToken (ERC20 _tokenContractAddress) public view returns (uint256) {
        ERC20 token = _tokenContractAddress;
        return token.balanceOf(this);
    }

    function transferToken(ERC20 _tokenContractAddress, address _to, uint256 _amount) public onlyAdmin{
        ERC20 token = _tokenContractAddress;
         
        token.transfer(_to,_amount);
        emit LogTokenTransfer(token,_to,_amount);
    }

    function batchTransferToken(ERC20 _tokenContractAddress,address[] _target,uint256[] _amount) onlyAdmin public {
        require(_target.length >= _amount.length);
        uint256 length = _target.length;
        ERC20 token = _tokenContractAddress;

        for (uint i=0; i<length; i++) {  
            token.transfer(_target[i],_amount[i]);
            emit LogTokenTransfer(token,_target[i],_amount[i]);       
        }
    }

    function giveTokenAllowance(ERC20 _tokenContractAddress, address _spender, uint256 _value) onlyAdmin public{
        ERC20 token = _tokenContractAddress;
        token.approve(_spender, _value);
        emit LogTokenAllowanceApprove(token,_spender, _value);
    }


     
    function() public {
        revert();
    }

}