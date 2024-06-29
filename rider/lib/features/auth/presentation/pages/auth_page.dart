import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:rider/features/ride_direction/presentation/pages/home.dart';
import 'package:rider/utils/colors.dart';

import '../../bloc/auth_bloc.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthenticationPageView();
  }
}

class AuthenticationPageView extends StatefulWidget {
  const AuthenticationPageView({super.key});

  @override
  State<AuthenticationPageView> createState() => _AuthenticationPageViewState();
}

class _AuthenticationPageViewState extends State<AuthenticationPageView> {
  RegExp phoneNumberRegex = RegExp(r'[a-zA-Z]');
  var phoneNumber = ""; // for storing phone number
  var otp = ""; // for storing otp
  var step = 0; // for initialization with Initial State

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: primaryColor,
      ),
      body: BlocListener<AuthenticationBloc,AuthenticationState>(
        listener: (BuildContext context,AuthenticationState state){
          if (state is AuthenticationInitialState){
            if (step != 0){
              setState(() {
                phoneNumber = "";
                step = 0;
              });
            }
          }
          else if (state is AuthenticationEnterOTPState){
            if (step != 1 || otp!=""){
              setState(() {
                otp = "";
                step = 1;
              });
            }
          }
          else if (state is AuthenticationVerifiedState){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const HomePage()
              )
            );
          }
          else if (state is AuthenticationErrorState){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage)
              ),
            );
          }
        },
        child: Container(
          color: primaryColor,
          child: Column(
            children: [
              if (step == 0) ...[
                // Enter your mobile number Text
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 10, 10, 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter your mobile number',
                    style: TextStyle(
                      fontSize: 21,
                      color: textColor,
                    ),
                  ),
                ),
                // Enter phone number field
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: IntlPhoneField(
                    dropdownTextStyle: TextStyle(color: placeholderTextColor),
                    dropdownIcon: Icon(Icons.arrow_drop_down,color: placeholderTextColor,),
                    style: TextStyle(color: placeholderTextColor),
                    decoration: InputDecoration(
                      prefixStyle: TextStyle(color: placeholderTextColor),
                      labelText: 'Phone Number',
                      floatingLabelStyle: TextStyle(color: placeholderTextColor),
                      labelStyle: TextStyle(color: placeholderTextColor),
                    ),
                    initialCountryCode: 'IN',
                    onChanged: (phone) {
                      phoneNumber = phone.completeNumber;
                    },
                  ),
                ),
                // Connect with Social -> TextButton
                SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextButton(
                    style: const ButtonStyle(
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () {},
                    child: const Text.rich(
                      TextSpan(
                          children: [
                            TextSpan(
                              text: 'Connect with social  ',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: '\u{2192}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 35,
                              ),
                            )
                          ]
                      ),
                    ),
                  ),
                ),
              ]
              else if (step == 1) ...[
                // Enter the otp... Text
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  alignment: Alignment.center,
                  child: Text(
                    'Enter the OTP sent to the number',
                    style: TextStyle(
                      fontSize: 21,
                      color: textColor,
                    ),
                  ),
                ),
                // <Phone Number> Text
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 19,
                      color: textColor,
                    ),
                  ),
                ),
                // Change Phone Number TextButton
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
                  child: TextButton(
                    onPressed: () {
                      BlocProvider.of<AuthenticationBloc>(context)
                          .add(AuthenticationPhoneNumberChangeRequest());
                    },
                    child: const Text(
                      'Change Phone Number',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                // OTP Input field
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 60, 0, 10),
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: Pinput(
                    defaultPinTheme: PinTheme(
                      width: 45,
                      height: 50,
                      textStyle: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFB4B4B4),width: 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    length: 6,
                    autofocus: true,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onChanged: (pin){
                      otp = pin;
                    },
                    onCompleted: (pin){
                      otp = pin;
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: TextButton(
                        onPressed: () {
                          BlocProvider.of<AuthenticationBloc>(context)
                              .add(AuthenticationResendOTPRequest(phoneNumber: phoneNumber));
                        },
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
              ],
              const Expanded(child: SizedBox()),
              if (step == 0) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: const Text(
                    'By continuing you may receive an SMS  verification. Message and data rates may apply.',
                    style: TextStyle(
                        color: Colors.grey
                    ),
                  ),
                ),
              ],
              Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                  width: MediaQuery.of(context).size.width*0.88,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (){
                      if (step == 0){
                        BlocProvider.of<AuthenticationBloc>(context)
                            .add(AuthenticationPhoneNumberEntered(phoneNumber: phoneNumber));
                      }
                      else if (step == 1){
                        BlocProvider.of<AuthenticationBloc>(context)
                            .add(AuthenticationOTPEntered(otp: otp));
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(buttonBlack),
                      foregroundColor: MaterialStateProperty.all<Color>(textColor),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                          fontSize: 20,
                          color: textColor
                      ),
                    ),
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}
