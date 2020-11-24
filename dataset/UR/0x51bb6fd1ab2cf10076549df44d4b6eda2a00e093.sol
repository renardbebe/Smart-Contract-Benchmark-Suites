 

pragma solidity 0.5.8;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint _amount) external returns (bool);
}

contract Tipbot {

    address payable public admin = msg.sender;
    IERC20 public ERC20;

    function changeOwnership(address _subject) public {
        require(msg.sender == admin);

        admin = address(uint160(_subject));
    }

    function multiTransfer(address _source, address[] memory _recievers, uint _amount) payable public {
        require(_recievers.length < 25);

        batchTransfer(_source, _recievers, _amount);
        admin.transfer(address(this).balance);
    }

    function tipTransfer(address _source, address _recipent, uint _amount) payable public {
      if(_source != address(0x0)){
        ERC20 = IERC20(_source);
        ERC20.transferFrom(msg.sender, _recipent, _amount);
      } else {
        address payable payee = address(uint160(_recipent));
        payee.transfer(_amount);
      } admin.transfer(address(this).balance);
    }

    function batchTransfer(address _source, address[] memory _recievers, uint _amount) public {
      if(_source != address(0x0)){
        ERC20 = IERC20(_source);
        for(uint x = 0; x < _recievers.length; x++){
          ERC20.transferFrom(msg.sender, _recievers[x], _amount);
        }
      } else {
        for(uint y = 0; y < _recievers.length; y++){
          address payable payee = address(uint160(_recievers[y]));
          payee.transfer(_amount);
        }
      }
    }

}