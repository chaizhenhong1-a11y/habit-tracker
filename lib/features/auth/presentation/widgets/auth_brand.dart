import 'dart:ui';

import 'package:flutter/material.dart';

class HabitBrand extends StatelessWidget {
  const HabitBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF3EFE4) : const Color(0xFF123D2B);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _HabitMark(size: compact ? 48 : 62),
      SizedBox(height: compact ? 7 : 10),
      Text('H A B I T', style: TextStyle(color: ink, fontSize: compact ? 17 : 20, fontWeight: FontWeight.w600, letterSpacing: 5.2)),
      const SizedBox(height: 4),
      Text('A  B E T T E R  Y O U  ·  E V E R Y  D A Y', style: TextStyle(color: ink.withValues(alpha: .58), fontSize: 7.5, fontWeight: FontWeight.w600, letterSpacing: 1.45)),
    ]);
  }
}

class _HabitMark extends StatelessWidget {
  const _HabitMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _MarkPainter()));
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stem = Paint()..color = const Color(0xFF244E39)..strokeWidth = s.width * .052..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s.width * .5, s.height * .86), Offset(s.width * .5, s.height * .37), stem);
    final left = Path()..moveTo(s.width*.47,s.height*.72)..cubicTo(s.width*.12,s.height*.61,s.width*.13,s.height*.23,s.width*.18,s.height*.17)..cubicTo(s.width*.43,s.height*.24,s.width*.53,s.height*.49,s.width*.47,s.height*.72)..close();
    canvas.drawPath(left, Paint()..shader=const LinearGradient(colors:[Color(0xFF9BAA78),Color(0xFF42694C)],begin:Alignment.topLeft,end:Alignment.bottomRight).createShader(Offset.zero & s));
    final right = Path()..moveTo(s.width*.53,s.height*.72)..cubicTo(s.width*.88,s.height*.61,s.width*.87,s.height*.28,s.width*.82,s.height*.22)..cubicTo(s.width*.58,s.height*.27,s.width*.48,s.height*.51,s.width*.53,s.height*.72)..close();
    canvas.drawPath(right, Paint()..shader=const LinearGradient(colors:[Color(0xFF78915F),Color(0xFF214B38)],begin:Alignment.topRight,end:Alignment.bottomLeft).createShader(Offset.zero & s));
    canvas.drawCircle(Offset(s.width*.68,s.height*.13),s.width*.105,Paint()..shader=const RadialGradient(colors:[Color(0xFFF2CF91),Color(0xFFD8A85D)]).createShader(Offset.zero&s));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Stack(fit:StackFit.expand,children:[
      DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:dark?const[Color(0xFF101B15),Color(0xFF18251C),Color(0xFF0B120E)]:const[Color(0xFFFFF9EF),Color(0xFFF4E4CD),Color(0xFFE6E9D9)]))),
      const Positioned(left:-120,right:-120,top:185,height:390,child:_Landscape()),
      Positioned(top:-90,right:-60,child:_SunGlow(dark:dark)),
      Positioned(right:-30,top:25,child:Transform.rotate(angle:-.22,child:const _LeafCluster(size:190,opacity:.35))),
      Positioned(left:-70,bottom:-30,child:Transform.rotate(angle:.42,child:const _LeafCluster(size:230,opacity:.42))),
      Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.white.withValues(alpha:dark?.015:.18),Colors.transparent,Colors.white.withValues(alpha:dark?.015:.12)])))),
      child,
    ]);
  }
}

class _SunGlow extends StatelessWidget { const _SunGlow({required this.dark}); final bool dark; @override Widget build(BuildContext context)=>Container(width:290,height:290,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[const Color(0xFFFFD7A1).withValues(alpha:dark?.08:.34),Colors.transparent]))); }

class _Landscape extends StatelessWidget { const _Landscape(); @override Widget build(BuildContext context)=>CustomPaint(painter:_LandscapePainter()); }
class _LandscapePainter extends CustomPainter {
  @override void paint(Canvas c,Size s){
    final far=Path()..moveTo(0,s.height*.63)..lineTo(s.width*.18,s.height*.45)..lineTo(s.width*.31,s.height*.57)..lineTo(s.width*.49,s.height*.31)..lineTo(s.width*.64,s.height*.54)..lineTo(s.width*.81,s.height*.38)..lineTo(s.width,s.height*.58)..lineTo(s.width,s.height)..lineTo(0,s.height)..close();
    c.drawPath(far,Paint()..color=const Color(0xFF87938A).withValues(alpha:.20));
    final near=Path()..moveTo(0,s.height*.75)..quadraticBezierTo(s.width*.22,s.height*.58,s.width*.43,s.height*.73)..quadraticBezierTo(s.width*.7,s.height*.9,s.width,s.height*.62)..lineTo(s.width,s.height)..lineTo(0,s.height)..close();
    c.drawPath(near,Paint()..color=const Color(0xFF3F6551).withValues(alpha:.13));
    c.drawRect(Rect.fromLTWH(0,s.height*.73,s.width,s.height*.27),Paint()..shader=LinearGradient(colors:[const Color(0xFFFFD6AD).withValues(alpha:.2),const Color(0xFF8DA89A).withValues(alpha:.13)]).createShader(Rect.fromLTWH(0,s.height*.73,s.width,s.height*.27)));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class _LeafCluster extends StatelessWidget { const _LeafCluster({required this.size,required this.opacity}); final double size,opacity; @override Widget build(BuildContext context)=>Opacity(opacity:opacity,child:SizedBox(width:size,height:size,child:CustomPaint(painter:_LeavesPainter()))); }
class _LeavesPainter extends CustomPainter { @override void paint(Canvas c,Size s){ final stem=Paint()..color=const Color(0xFF315D42)..strokeWidth=2; c.drawLine(Offset(s.width*.1,s.height),Offset(s.width*.82,0),stem); for(final p in const[[.28,.72,-.7],[.42,.52,.55],[.58,.34,-.72],[.72,.16,.52]]){c.save();c.translate(s.width*(p[0] as double),s.height*(p[1] as double));c.rotate(p[2] as double);final leaf=Path()..moveTo(0,0)..quadraticBezierTo(s.width*.22,-s.height*.10,s.width*.28,0)..quadraticBezierTo(s.width*.15,s.height*.15,0,0)..close();c.drawPath(leaf,Paint()..shader=const LinearGradient(colors:[Color(0xFF9CAB79),Color(0xFF3D684A)]).createShader(Rect.fromLTWH(0,-30,80,80)));c.restore();}} @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }

class PremiumAuthField extends StatelessWidget {
  const PremiumAuthField({super.key,required this.controller,required this.hint,required this.icon,this.focusNode,this.obscureText=false,this.suffix,this.validator,this.autofillHints,this.textInputAction,this.onFieldSubmitted});
  final TextEditingController controller; final FocusNode? focusNode; final String hint; final IconData icon; final bool obscureText; final Widget? suffix; final String? Function(String?)? validator; final Iterable<String>? autofillHints; final TextInputAction? textInputAction; final ValueChanged<String>? onFieldSubmitted;
  @override Widget build(BuildContext context){ final dark=Theme.of(context).brightness==Brightness.dark; return ClipRRect(borderRadius:BorderRadius.circular(22),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:18,sigmaY:18),child:TextFormField(controller:controller,focusNode:focusNode,obscureText:obscureText,autofillHints:autofillHints,textInputAction:textInputAction,onFieldSubmitted:onFieldSubmitted,validator:validator,autovalidateMode:AutovalidateMode.disabled,style:TextStyle(fontSize:16,color:dark?const Color(0xFFF5F0E8):const Color(0xFF27352D)),decoration:InputDecoration(hintText:hint,prefixIcon:Icon(icon,size:21),suffixIcon:suffix,filled:true,fillColor:dark?Colors.white.withValues(alpha:.08):Colors.white.withValues(alpha:.48),contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:19),border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide(color:Colors.white.withValues(alpha:.58))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide(color:Colors.white.withValues(alpha:dark?.12:.68))),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide(color:dark?const Color(0xFF8EAD91):const Color(0xFF456A55),width:1.3)),errorBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:Color(0xFFB75A4E)))))))); }
}

ButtonStyle premiumAuthButtonStyle(BuildContext context)=>FilledButton.styleFrom(backgroundColor:const Color(0xFF194B36),foregroundColor:Colors.white,disabledBackgroundColor:const Color(0xFF194B36).withValues(alpha:.45),elevation:10,shadowColor:const Color(0xFF173E2D).withValues(alpha:.28),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)));
