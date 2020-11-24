 

contract MutableForwarder is DelegateProxy, DSAuth {

  address public target = 0xf4e6e033921b34f89b0586beb2d529e8eae3e021;  

   
  function setTarget(address _target) public auth {
    target = _target;
  }

  function() payable {
    delegatedFwd(target, msg.data);
  }

}