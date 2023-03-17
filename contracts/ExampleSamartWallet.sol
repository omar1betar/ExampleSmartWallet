//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;
contract Consumer 
{
    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }
    function deposite() public payable{}
}
contract SmartContractWallet
{
    address  payable public owner;
    mapping (address => uint) public allowance;
    mapping (address => bool) public isAllowedToSend;
    mapping (address => bool) public guardians;
    mapping (address => mapping(address=>bool)) public nextOwnerGuardianVotedBefore;

    address payable nextOwner;
    uint guardiansRestCount;
    uint public confiramtionFromGuardiansForReset =3;

    constructor()
    {
        owner = payable(msg.sender);
    } 
    function setGuardian(address _guardian, bool _isGuardian) public
    {
        require(msg.sender ==owner,"You are not the owner");
        guardians[_guardian] = _isGuardian;
    }
    function proposeNewOwner(address payable _newOwner)public 
    {
        require(guardians[msg.sender],"You are not  guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBefore[_newOwner][msg.sender]==false,"You already voted, aborting");
        if(_newOwner != nextOwner)
        {
            nextOwner = _newOwner;
            guardiansRestCount =0;
        }
        guardiansRestCount++;
        if(guardiansRestCount >= confiramtionFromGuardiansForReset)
        {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }
    function setAllowance(address _for,uint _amount)public 
    {
        require(msg.sender ==owner,"You are not the owner");
        allowance[_for] =_amount;
        if(_amount > 0){
            isAllowedToSend[_for] = true;
        }else{
            isAllowedToSend[_for] = false;
        }
    }
    function transfer(address payable _to,uint _amount,bytes memory _payload) public returns(bytes memory)
    {
       // require(msg.sender == owner,"You are not the owner, aborting");
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender] ,"You are not allowed to send anything from this contract, aborting");
            require(allowance[msg.sender] >= _amount ,"You are trying to send more money then you are allowed to , aborting");
            allowance[msg.sender] -= _amount;
        }
        (bool success,bytes memory returnData ) =_to.call{value:_amount}(_payload);
        require(success,"Aborting, call wa not success");
        return returnData;
    }

    receive() external payable{}
}